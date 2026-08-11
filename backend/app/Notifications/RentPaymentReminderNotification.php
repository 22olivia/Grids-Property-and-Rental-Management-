<?php

namespace App\Notifications;

use App\Models\Payment;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class RentPaymentReminderNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(public Payment $payment) {}

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $status = $this->payment->status;
        $amount = $this->payment->amount;
        $due = optional($this->payment->due_date)->toFormattedDateString() ?? 'N/A';
        $period = $this->payment->period ?? 'current period';

        $subject = $status === 'overdue'
            ? 'Overdue rent payment reminder'
            : 'Upcoming rent payment reminder';

        return (new MailMessage)
            ->subject($subject)
            ->greeting('Hello '.$this->notifiableName($notifiable).',')
            ->line("This is an automated reminder for your rent payment ({$period}).")
            ->line("Amount: {$amount}")
            ->line("Due date: {$due}")
            ->line('Status: '.ucfirst($status))
            ->line('Please pay on time to avoid late fees.')
            ->salutation('Grids Property Management');
    }

    private function notifiableName(object $notifiable): string
    {
        return $notifiable->full_name
            ?? $notifiable->name
            ?? 'Tenant';
    }
}
