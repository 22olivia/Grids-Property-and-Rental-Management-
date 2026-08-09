<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Auth\Notifications\ResetPassword;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\Password;
use Tests\TestCase;

class AuthApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_sign_up(): void
    {
        $response = $this->postJson('/api/v1/signup', [
            'name' => 'New User',
            'email' => 'new@example.com',
            'password' => 'password',
            'password_confirmation' => 'password',
            'role' => 'admin',
        ]);

        $response->assertCreated()
            ->assertJsonStructure(['message', 'user', 'token']);

        $this->assertDatabaseHas('users', [
            'email' => 'new@example.com',
            'role' => 'super_admin',
        ]);
    }

    public function test_user_can_register(): void
    {
        $response = $this->postJson('/api/v1/register', [
            'name' => 'New User',
            'email' => 'register@example.com',
            'password' => 'password',
            'password_confirmation' => 'password',
        ]);

        $response->assertCreated()
            ->assertJsonStructure(['message', 'user', 'token']);
    }

    public function test_user_can_login(): void
    {
        $user = User::factory()->create([
            'email' => 'login@example.com',
            'password' => 'password',
        ]);

        $response = $this->postJson('/api/v1/login', [
            'email' => $user->email,
            'password' => 'password',
        ]);

        $response->assertOk()
            ->assertJsonStructure(['message', 'user', 'token']);
    }

    public function test_login_prompts_signup_when_email_missing(): void
    {
        $response = $this->postJson('/api/v1/login', [
            'email' => 'missing@example.com',
            'password' => 'password',
        ]);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors(['email']);
    }

    public function test_authenticated_user_can_fetch_profile(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/me');

        $response->assertOk()
            ->assertJsonPath('user.email', $user->email);
    }

    public function test_forgot_password_sends_reset_email(): void
    {
        Notification::fake();

        $user = User::factory()->create([
            'email' => 'reset@example.com',
        ]);

        $response = $this->postJson('/api/v1/forgot-password', [
            'email' => $user->email,
        ]);

        $response->assertOk()
            ->assertJsonPath('message', 'Password reset link sent to your email.');

        Notification::assertSentTo($user, ResetPassword::class);
    }

    public function test_user_can_reset_password_with_token(): void
    {
        $user = User::factory()->create([
            'email' => 'resetme@example.com',
            'password' => 'old-password',
        ]);

        $token = Password::broker()->createToken($user);

        $response = $this->postJson('/api/v1/reset-password', [
            'email' => $user->email,
            'token' => $token,
            'password' => 'new-password',
            'password_confirmation' => 'new-password',
        ]);

        $response->assertOk();

        $this->assertTrue(Hash::check('new-password', $user->fresh()->password));
    }

    public function test_user_can_upload_and_remove_profile_photo(): void
    {
        \Illuminate\Support\Facades\Storage::fake('public');

        $user = User::factory()->create();

        $tmp = tempnam(sys_get_temp_dir(), 'avatar');
        file_put_contents($tmp, 'fake-jpeg-bytes');
        $file = new \Illuminate\Http\UploadedFile(
            $tmp,
            'avatar.jpg',
            'image/jpeg',
            null,
            true,
        );

        $upload = $this->actingAs($user, 'sanctum')
            ->post('/api/v1/profile/photo', [
                'photo' => $file,
            ], [
                'Accept' => 'application/json',
            ]);

        $upload->assertOk()
            ->assertJsonPath('message', 'Profile photo updated.');

        $user->refresh();
        $this->assertNotNull($user->photo_path);
        \Illuminate\Support\Facades\Storage::disk('public')->assertExists($user->photo_path);
        $this->assertNotNull($upload->json('user.photo_url'));

        $delete = $this->actingAs($user, 'sanctum')
            ->deleteJson('/api/v1/profile/photo');

        $delete->assertOk()
            ->assertJsonPath('message', 'Profile photo removed.');

        $user->refresh();
        $this->assertNull($user->photo_path);
    }
}
