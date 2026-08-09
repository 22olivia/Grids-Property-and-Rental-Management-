<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;

class DemoAlertNotification extends Notification
{
    use Queueable;

    /**
     * @param  array{title:string,body:string,category?:string,href?:string}  $payload
     */
    public function __construct(public array $payload) {}

    public function via(object $notifiable): array
    {
        return ['database'];
    }

    /**
     * @return array<string, mixed>
     */
    public function toArray(object $notifiable): array
    {
        return [
            'title' => $this->payload['title'],
            'body' => $this->payload['body'],
            'category' => $this->payload['category'] ?? 'general',
            'href' => $this->payload['href'] ?? '/notifications',
        ];
    }
}
