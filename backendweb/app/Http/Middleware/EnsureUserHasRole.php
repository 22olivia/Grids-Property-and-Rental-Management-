<?php

namespace App\Http\Middleware;

use App\Support\Roles;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureUserHasRole
{
    /**
     * @param  Closure(Request): Response  $next
     */
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        $user = $request->user();

        if (! $user) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }

        if (($user->status ?? 'active') !== 'active') {
            return response()->json(['message' => 'Account is not active.'], 403);
        }

        $normalized = Roles::normalize($user->role);
        $allowed = collect($roles)->map(fn ($role) => Roles::normalize($role))->all();

        if (! in_array($normalized, $allowed, true)) {
            return response()->json(['message' => 'You do not have permission for this action.'], 403);
        }

        return $next($request);
    }
}
