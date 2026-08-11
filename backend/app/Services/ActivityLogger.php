<?php

namespace App\Services;

use App\Models\ActivityLog;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\Request;

class ActivityLogger
{
    public function log(string $action, ?Model $subject = null, array $properties = [], ?Request $request = null): void
    {
        $request ??= request();

        ActivityLog::query()->create([
            'user_id' => $request?->user()?->id,
            'action' => $action,
            'subject_type' => $subject ? $subject::class : null,
            'subject_id' => $subject?->getKey(),
            'properties' => $properties ?: null,
            'ip_address' => $request?->ip(),
        ]);
    }
}
