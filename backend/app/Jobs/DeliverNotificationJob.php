<?php

namespace App\Jobs;

use App\Models\AppNotification;
use App\Services\NotificationService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

class DeliverNotificationJob implements ShouldQueue
{
    use Queueable;

    public int $tries = 5;

    public function __construct(public readonly string $notificationId) {}

    public function handle(NotificationService $notifications): void
    {
        $notification = AppNotification::query()->find($this->notificationId);
        if (! $notification) {
            return;
        }

        $notifications->deliver($notification);
    }
}
