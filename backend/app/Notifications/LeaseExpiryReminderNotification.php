<?php

namespace App\Notifications;

use App\Models\Contract;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class LeaseExpiryReminderNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(public Contract $contract) {}

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $end = optional($this->contract->end_date)->toFormattedDateString() ?? 'N/A';
        $number = $this->contract->contract_number;

        return (new MailMessage)
            ->subject('Lease expiry reminder')
            ->greeting('Hello '.$this->notifiableName($notifiable).',')
            ->line("Your lease {$number} is approaching expiry.")
            ->line("End date: {$end}")
            ->line('Please contact property management if you wish to renew.')
            ->salutation('Grids Property Management');
    }

    private function notifiableName(object $notifiable): string
    {
        return $notifiable->full_name
            ?? $notifiable->name
            ?? 'Tenant';
    }
}
