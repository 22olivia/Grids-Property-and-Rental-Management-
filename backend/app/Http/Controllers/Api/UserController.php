<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Owner;
use App\Models\Tenant;
use App\Models\User;
use App\Services\ActivityLogger;
use App\Support\Roles;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password as PasswordRule;

class UserController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $users = User::query()
            ->when($request->search, function ($q) use ($request) {
                $term = '%'.$request->search.'%';
                $q->where(function ($inner) use ($term) {
                    $inner->where('name', 'like', $term)
                        ->orWhere('email', 'like', $term)
                        ->orWhere('phone', 'like', $term);
                });
            })
            ->when($request->role, fn ($q) => $q->where('role', Roles::normalize($request->role)))
            ->when($request->status, fn ($q) => $q->where('status', $request->status))
            ->latest()
            ->paginate((int) $request->get('per_page', 15));

        return response()->json($users);
    }

    public function store(Request $request, ActivityLogger $logger): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'phone' => ['nullable', 'string', 'max:50'],
            'address' => ['nullable', 'string'],
            'organization_id' => ['nullable', 'exists:organizations,id'],
            'role' => ['required', Rule::in(Roles::all())],
            'status' => ['sometimes', Rule::in(['active', 'inactive', 'suspended'])],
            'verification_status' => ['sometimes', Rule::in(['unverified', 'pending', 'verified', 'rejected'])],
            'assigned_property_ids' => ['sometimes', 'array'],
            'assigned_unit_ids' => ['sometimes', 'array'],
            'password' => ['required', 'confirmed', PasswordRule::defaults()],
            'photo_path' => ['nullable', 'string', 'max:255'],
        ]);

        $validated['role'] = Roles::normalize($validated['role']);
        $validated['status'] ??= 'active';
        $validated['verification_status'] ??= 'verified';

        $user = User::create($validated);
        $this->syncDomainProfile($user);

        $logger->log('user.created', $user, ['role' => $user->role], $request);

        return response()->json([
            'message' => 'User created successfully.',
            'data' => $user,
        ], 201);
    }

    public function show(User $user): JsonResponse
    {
        $user->load(['loginHistories' => fn ($q) => $q->latest('logged_in_at')->limit(20)]);

        return response()->json([
            'data' => $user,
            'role_label' => Roles::label($user->role),
        ]);
    }

    public function update(Request $request, User $user, ActivityLogger $logger): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'email' => ['sometimes', 'email', 'max:255', Rule::unique('users', 'email')->ignore($user->id)],
            'phone' => ['nullable', 'string', 'max:50'],
            'address' => ['nullable', 'string'],
            'role' => ['sometimes', Rule::in(Roles::all())],
            'status' => ['sometimes', Rule::in(['active', 'inactive', 'suspended'])],
            'photo_path' => ['nullable', 'string', 'max:255'],
            'password' => ['nullable', 'confirmed', PasswordRule::defaults()],
        ]);

        if (isset($validated['role'])) {
            $validated['role'] = Roles::normalize($validated['role']);
        }

        if (empty($validated['password'])) {
            unset($validated['password']);
        }

        $user->update($validated);
        $this->syncDomainProfile($user->fresh());

        $logger->log('user.updated', $user, $validated, $request);

        return response()->json([
            'message' => 'User updated successfully.',
            'data' => $user->fresh(),
        ]);
    }

    public function destroy(User $user, ActivityLogger $logger): JsonResponse
    {
        if ($user->id === auth()->id()) {
            return response()->json(['message' => 'You cannot delete your own account.'], 422);
        }

        $logger->log('user.deleted', $user, ['email' => $user->email]);
        $user->delete();

        return response()->json(['message' => 'User deleted successfully.']);
    }

    public function deactivate(User $user, ActivityLogger $logger): JsonResponse
    {
        $user->update(['status' => 'inactive']);
        $logger->log('user.deactivated', $user);

        return response()->json([
            'message' => 'User deactivated.',
            'data' => $user,
        ]);
    }

    public function stats(): JsonResponse
    {
        return response()->json([
            'data' => [
                'total_users' => User::count(),
                'active_users' => User::where('status', 'active')->count(),
                'inactive_users' => User::where('status', 'inactive')->count(),
                'suspended_users' => User::where('status', 'suspended')->count(),
                'super_admins' => User::where('role', Roles::SUPER_ADMIN)->count(),
                'owners' => User::where('role', Roles::OWNER)->count(),
                'managers' => User::where('role', Roles::MANAGER)->count(),
                'accountants' => User::where('role', Roles::ACCOUNTANT)->count(),
                'agents' => User::where('role', Roles::AGENT)->count(),
                'tenants' => User::where('role', Roles::TENANT)->count(),
                'vendors' => User::where('role', Roles::VENDOR)->count(),
                'technicians' => User::where('role', Roles::TECHNICIAN)->count(),
                'recent_users' => User::latest()->limit(5)->get(['id', 'name', 'email', 'role', 'status', 'created_at']),
            ],
        ]);
    }

    public function roles(): JsonResponse
    {
        return response()->json([
            'data' => collect(Roles::all())->map(fn ($role) => [
                'value' => $role,
                'label' => Roles::label($role),
            ]),
            'permissions' => Roles::permissions(),
        ]);
    }

    private function syncDomainProfile(User $user): void
    {
        if ($user->normalizedRole() === Roles::OWNER) {
            Owner::query()->updateOrCreate(
                ['email' => $user->email],
                [
                    'user_id' => $user->id,
                    'full_name' => $user->name,
                    'phone' => $user->phone,
                    'address' => $user->address,
                ],
            );
        }

        if ($user->normalizedRole() === Roles::TENANT) {
            Tenant::query()->updateOrCreate(
                ['email' => $user->email],
                [
                    'user_id' => $user->id,
                    'full_name' => $user->name,
                    'phone' => $user->phone,
                ],
            );
        }

        if ($user->normalizedRole() === Roles::VENDOR) {
            \App\Models\Vendor::query()->updateOrCreate(
                ['email' => $user->email],
                [
                    'user_id' => $user->id,
                    'organization_id' => $user->organization_id,
                    'company_name' => $user->name.' Services',
                    'contact_name' => $user->name,
                    'phone' => $user->phone,
                    'status' => 'active',
                ],
            );
        }
    }
}
