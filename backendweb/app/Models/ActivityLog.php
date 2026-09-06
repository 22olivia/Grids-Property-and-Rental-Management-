<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphTo;
use Illuminate\Http\Request;

#[Fillable([
    'user_id',
    'action',
    'subject_type',
    'subject_id',
    'properties',
    'ip_address',
])]
class ActivityLog extends Model
{
    protected function casts(): array
    {
        return [
            'properties' => 'array',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function subject(): MorphTo
    {
        return $this->morphTo();
    }

    /**
     * Record an auditable action (replaces the former ActivityLogger service).
     *
     * subject_id is an unsigned bigint in MySQL — UUID / string keys (e.g. support
     * tickets) cannot be stored there. Keep subject_type and put the real key in
     * properties.subject_key so audits still work without 500s.
     */
    public static function record(string $action, ?Model $subject = null, array $properties = [], ?Request $request = null): void
    {
        $request ??= request();

        $subjectId = null;
        if ($subject) {
            $key = $subject->getKey();
            if (is_int($key) || (is_string($key) && ctype_digit($key))) {
                $subjectId = (int) $key;
            } else {
                $properties['subject_key'] = (string) $key;
            }
        }

        static::query()->create([
            'user_id' => $request?->user()?->id,
            'action' => $action,
            'subject_type' => $subject ? $subject::class : null,
            'subject_id' => $subjectId,
            'properties' => $properties ?: null,
            'ip_address' => $request?->ip(),
        ]);
    }
}
