<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Organization;
use App\Services\ActivityLogger;
use App\Support\Roles;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class OrganizationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $orgs = Organization::query()
            ->with(['ownerUser:id,name,email'])
            ->withCount(['properties', 'users'])
            ->when(! $user->isSuperAdmin(), function ($q) use ($user) {
                $q->where(function ($inner) use ($user) {
                    $inner->where('owner_user_id', $user->id)
                        ->orWhere('id', $user->organization_id)
                        ->orWhereHas('users', fn ($u) => $u->where('users.id', $user->id));
                });
            })
            ->latest()
            ->paginate((int) $request->get('per_page', 20));

        return response()->json($orgs);
    }

    public function store(Request $request, ActivityLogger $logger): JsonResponse
    {
        abort_unless($request->user()->isSuperAdmin() || $request->user()->isOwner(), 403);

        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'legal_name' => ['nullable', 'string', 'max:255'],
            'email' => ['nullable', 'email'],
            'phone' => ['nullable', 'string', 'max:50'],
            'country' => ['nullable', 'string', 'max:100'],
            'city' => ['nullable', 'string', 'max:100'],
            'address' => ['nullable', 'string'],
            'plan' => ['sometimes', Rule::in(['starter', 'growth', 'enterprise'])],
            'maintenance_approval_limit' => ['sometimes', 'numeric', 'min:0'],
            'owner_user_id' => ['nullable', 'exists:users,id'],
            'status' => ['sometimes', Rule::in(['active', 'inactive', 'suspended'])],
        ]);

        $org = Organization::create([
            ...$validated,
            'slug' => Str::slug($validated['name']).'-'.Str::lower(Str::random(4)),
            'owner_user_id' => $validated['owner_user_id'] ?? $request->user()->id,
            'plan' => $validated['plan'] ?? 'starter',
            'status' => $validated['status'] ?? 'active',
        ]);

        $org->users()->syncWithoutDetaching([
            $org->owner_user_id => [
                'role' => Roles::OWNER,
                'status' => 'active',
                'permissions' => json_encode(Roles::permissions()[Roles::OWNER]),
            ],
        ]);

        $logger->log('organization.created', $org, $validated, $request);

        return response()->json([
            'message' => 'Organization created.',
            'data' => $org->load('ownerUser'),
        ], 201);
    }

    public function show(Organization $organization): JsonResponse
    {
        $organization->load(['ownerUser', 'users:id,name,email,role,status', 'properties']);

        return response()->json(['data' => $organization]);
    }

    public function update(Request $request, Organization $organization, ActivityLogger $logger): JsonResponse
    {
        abort_unless(
            $request->user()->isSuperAdmin()
            || $organization->owner_user_id === $request->user()->id
            || $request->user()->organization_id === $organization->id,
            403
        );

        $validated = $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'legal_name' => ['nullable', 'string', 'max:255'],
            'email' => ['nullable', 'email'],
            'phone' => ['nullable', 'string', 'max:50'],
            'country' => ['nullable', 'string', 'max:100'],
            'city' => ['nullable', 'string', 'max:100'],
            'address' => ['nullable', 'string'],
            'plan' => ['sometimes', Rule::in(['starter', 'growth', 'enterprise'])],
            'maintenance_approval_limit' => ['sometimes', 'numeric', 'min:0'],
            'status' => ['sometimes', Rule::in(['active', 'inactive', 'suspended'])],
            'owner_user_id' => ['nullable', 'exists:users,id'],
            'settings' => ['sometimes', 'array'],
        ]);

        $organization->update($validated);
        if (! empty($validated['owner_user_id'])) {
            $organization->users()->syncWithoutDetaching([
                $validated['owner_user_id'] => [
                    'role' => Roles::OWNER,
                    'status' => 'active',
                    'permissions' => json_encode(Roles::permissions()[Roles::OWNER]),
                ],
            ]);
        }
        $logger->log('organization.updated', $organization, $validated, $request);

        return response()->json([
            'message' => 'Organization updated.',
            'data' => $organization->fresh('ownerUser'),
        ]);
    }

    public function destroy(Organization $organization, ActivityLogger $logger): JsonResponse
    {
        abort_unless(auth()->user()?->isSuperAdmin(), 403);
        $logger->log('organization.deleted', $organization, ['name' => $organization->name]);
        $organization->delete();

        return response()->json(['message' => 'Organization deleted.']);
    }

    public function assignUser(Request $request, Organization $organization, ActivityLogger $logger): JsonResponse
    {
        abort_unless(
            $request->user()->isSuperAdmin() || $organization->owner_user_id === $request->user()->id,
            403
        );

        $validated = $request->validate([
            'user_id' => ['required', 'exists:users,id'],
            'role' => ['required', Rule::in(Roles::all())],
            'permissions' => ['sometimes', 'array'],
            'status' => ['sometimes', Rule::in(['active', 'inactive'])],
        ]);

        $permissions = $validated['permissions']
            ?? Roles::permissions()[Roles::normalize($validated['role'])]
            ?? [];

        $organization->users()->syncWithoutDetaching([
            $validated['user_id'] => [
                'role' => Roles::normalize($validated['role']),
                'status' => $validated['status'] ?? 'active',
                'permissions' => json_encode($permissions),
            ],
        ]);

        $logger->log('organization.user_assigned', $organization, $validated, $request);

        return response()->json([
            'message' => 'User assigned to organization.',
            'data' => $organization->load('users'),
        ]);
    }
}
