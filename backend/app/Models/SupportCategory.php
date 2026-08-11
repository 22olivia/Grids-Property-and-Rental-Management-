<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SupportCategory extends Model
{
    protected $fillable = [
        'key',
        'name',
        'route_to',
        'description',
        'is_active',
        'sort_order',
    ];

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
        ];
    }
}
