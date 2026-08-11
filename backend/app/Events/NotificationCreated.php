<?php

namespace App\Events;

use App\Models\AppNotification;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

/**
 * Real-time in-app notification fan-out.
 * Configure BROADCAST_CONNECTION (pusher/ably/redis) in production.
 * Local/demo defaults to log driver; the centre also polls unread count.
 */
class NotificationCreated implements ShouldBroadcast
{
    use Dispatchable, SerializesModels;

    public function __construct(public AppNotification $notification) {}

    public function broadcastOn(): array
    {
        return [
            new PrivateChannel('users.'.$this->notification->recipient_user_id),
        ];
    }

    public function broadcastAs(): string
    {
        return 'notification.created';
    }

    /**
     * @return array<string, mixed>
     */
    public function broadcastWith(): array
    {
        return [
            'id' => $this->notification->id,
            'title' => $this->notification->title,
            'message' => $this->notification->message,
            'category' => $this->notification->category,
            'priority' => $this->notification->priority,
            'action_url' => $this->notification->action_url,
            'unread' => true,
        ];
    }
}
