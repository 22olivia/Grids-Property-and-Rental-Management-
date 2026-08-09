<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\LoginHistory;
use App\Models\Owner;
use App\Models\Tenant;
use App\Models\User;
use App\Services\ActivityLogger;
use App\Support\Roles;
use Illuminate\Auth\Events\PasswordReset;
use Illuminate\Auth\Events\Verified;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password as PasswordRule;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function signup(Request $request): JsonResponse
    {
        return $this->register($request);
    }

    public function register(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'confirmed', PasswordRule::defaults()],
            'role' => ['sometimes', Rule::in([...Roles::all(), 'admin', 'staff'])],
            'phone' => ['nullable', 'string', 'max:50'],
            'address' => ['nullable', 'string'],
        ]);

        $role = Roles::normalize($validated['role'] ?? Roles::TENANT);

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => $validated['password'],
            'role' => $role,
            'phone' => $validated['phone'] ?? null,
            'address' => $validated['address'] ?? null,
            'status' => 'active',
        ]);

        if ($role === Roles::OWNER) {
            Owner::query()->updateOrCreate(
                ['email' => $user->email],
                ['user_id' => $user->id, 'full_name' => $user->name, 'phone' => $user->phone, 'address' => $user->address],
            );
        }

        if ($role === Roles::TENANT) {
            Tenant::query()->updateOrCreate(
                ['email' => $user->email],
                ['user_id' => $user->id, 'full_name' => $user->name, 'phone' => $user->phone],
            );
        }

        // Demo-friendly verification marker (real mail link can replace this later).
        $user->forceFill(['email_verified_at' => now()])->save();

        $token = $user->createToken('api-token')->plainTextToken;

        return response()->json([
            'message' => 'Sign up successful.',
            'user' => $user->fresh(),
            'token' => $token,
        ], 201);
    }

    public function login(Request $request, ActivityLogger $logger): JsonResponse
    {
        $credentials = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        $user = User::where('email', $credentials['email'])->first();

        if (! $user) {
            throw ValidationException::withMessages([
                'email' => ['No account found with this email. Please sign up.'],
            ]);
        }

        if (($user->status ?? 'active') !== 'active') {
            throw ValidationException::withMessages([
                'email' => ['This account is inactive or suspended.'],
            ]);
        }

        if (! Hash::check($credentials['password'], $user->password)) {
            throw ValidationException::withMessages([
                'password' => ['Incorrect password. Use forgot password if you need to reset it.'],
            ]);
        }

        $allowedRoles = [
            Roles::SUPER_ADMIN,
            Roles::OWNER,
            Roles::MANAGER,
            Roles::TENANT,
        ];
        if (! in_array($user->normalizedRole(), $allowedRoles, true)) {
            throw ValidationException::withMessages([
                'email' => ['Only Super Admin, Owner, Manager, and Tenant accounts can sign in.'],
            ]);
        }

        Auth::login($user);
        $user->forceFill(['last_login_at' => now()])->save();

        LoginHistory::query()->create([
            'user_id' => $user->id,
            'ip_address' => $request->ip(),
            'user_agent' => Str::limit((string) $request->userAgent(), 250, ''),
            'logged_in_at' => now(),
        ]);

        $logger->log('auth.login', $user, [], $request);
        $token = $user->createToken('api-token')->plainTextToken;

        return response()->json([
            'message' => 'Login successful.',
            'user' => $user->fresh(),
            'token' => $token,
            'role_label' => Roles::label($user->role),
        ]);
    }

    public function forgotPassword(Request $request): JsonResponse
    {
        $request->validate(['email' => ['required', 'email']]);

        $status = Password::sendResetLink($request->only('email'));

        if ($status !== Password::RESET_LINK_SENT) {
            throw ValidationException::withMessages([
                'email' => [__($status)],
            ]);
        }

        return response()->json([
            'message' => 'Password reset link sent to your email.',
            'status' => __($status),
        ]);
    }

    public function resetPassword(Request $request): JsonResponse
    {
        $request->validate([
            'token' => ['required', 'string'],
            'email' => ['required', 'email'],
            'password' => ['required', 'confirmed', PasswordRule::defaults()],
        ]);

        $status = Password::reset(
            $request->only('email', 'password', 'password_confirmation', 'token'),
            function (User $user) use ($request) {
                $user->forceFill([
                    'password' => $request->password,
                    'remember_token' => Str::random(60),
                ])->save();

                event(new PasswordReset($user));
            }
        );

        if ($status !== Password::PASSWORD_RESET) {
            throw ValidationException::withMessages([
                'email' => [__($status)],
            ]);
        }

        return response()->json([
            'message' => 'Password has been reset successfully. You can log in now.',
            'status' => __($status),
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        $user = $request->user()->load(['owner', 'tenant', 'managedProperties']);

        return response()->json([
            'user' => $user,
            'role_label' => Roles::label($user->role),
        ]);
    }

    public function updateProfile(Request $request, ActivityLogger $logger): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'phone' => ['nullable', 'string', 'max:50'],
            'address' => ['nullable', 'string'],
        ]);

        $user->update($validated);
        $logger->log('profile.updated', $user, $validated, $request);

        return response()->json([
            'message' => 'Profile updated.',
            'user' => $user->fresh(),
        ]);
    }

    public function uploadPhoto(Request $request, ActivityLogger $logger): JsonResponse
    {
        $request->validate([
            'photo' => ['required', 'file', 'max:2048'],
        ]);

        $file = $request->file('photo');
        $extension = strtolower((string) $file->getClientOriginalExtension());
        $allowed = ['jpg', 'jpeg', 'png', 'webp', 'gif'];
        if (! in_array($extension, $allowed, true)) {
            throw ValidationException::withMessages([
                'photo' => ['Upload a JPG, PNG, WEBP, or GIF image (max 2MB).'],
            ]);
        }

        $user = $request->user();
        $this->deleteStoredPhoto($user->photo_path);

        $path = $file->storeAs(
            'avatars',
            $user->id.'_'.Str::uuid()->toString().'.'.$extension,
            'public',
        );
        $user->update(['photo_path' => $path]);
        $logger->log('profile.photo_updated', $user, ['photo_path' => $path], $request);

        $fresh = $user->fresh();

        return response()->json([
            'message' => 'Profile photo updated.',
            'user' => $fresh,
            'photo_url' => $fresh?->photo_url,
        ]);
    }

    public function deletePhoto(Request $request, ActivityLogger $logger): JsonResponse
    {
        $user = $request->user();
        $this->deleteStoredPhoto($user->photo_path);
        $user->update(['photo_path' => null]);
        $logger->log('profile.photo_removed', $user, [], $request);

        return response()->json([
            'message' => 'Profile photo removed.',
            'user' => $user->fresh(),
        ]);
    }

    private function deleteStoredPhoto(?string $path): void
    {
        if (! $path) {
            return;
        }

        if (
            str_starts_with($path, 'http://')
            || str_starts_with($path, 'https://')
            || str_starts_with($path, 'data:')
            || str_starts_with($path, '/')
        ) {
            return;
        }

        Storage::disk('public')->delete($path);
    }

    public function changePassword(Request $request, ActivityLogger $logger): JsonResponse
    {
        $validated = $request->validate([
            'current_password' => ['required', 'string'],
            'password' => ['required', 'confirmed', PasswordRule::defaults()],
        ]);

        $user = $request->user();

        if (! Hash::check($validated['current_password'], $user->password)) {
            throw ValidationException::withMessages([
                'current_password' => ['Current password is incorrect.'],
            ]);
        }

        $user->update(['password' => $validated['password']]);
        $logger->log('profile.password_changed', $user, [], $request);

        return response()->json(['message' => 'Password changed successfully.']);
    }

    public function verifyEmail(Request $request): JsonResponse
    {
        $user = $request->user();

        if ($user->hasVerifiedEmail()) {
            return response()->json(['message' => 'Email already verified.', 'user' => $user]);
        }

        $user->markEmailAsVerified();
        event(new Verified($user));

        return response()->json([
            'message' => 'Email verified successfully.',
            'user' => $user->fresh(),
        ]);
    }

    public function loginHistory(Request $request): JsonResponse
    {
        $rows = $request->user()
            ->loginHistories()
            ->latest('logged_in_at')
            ->paginate(20);

        return response()->json($rows);
    }

    public function notifications(Request $request): JsonResponse
    {
        return response()->json([
            'data' => $request->user()->notifications()->latest()->limit(50)->get(),
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Logged out successfully.',
        ]);
    }
}
