<?php

namespace App\Notifications;

use App\Models\Contract;
use App\Models\Payment;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

/**
 * Tenant mail reminders for rent due/overdue and lease expiry.
 */
class TenantReminderNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(
        public readonly string $kind,
        public readonly Contract|Payment $subject,
    ) {}

    public static function rent(Payment $payment): self
    {
        return new self('rent', $payment);
    }

    public static function leaseExpiry(Contract $contract): self
    {
        return new self('lease_expiry', $contract);
    }

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $name = $notifiable->full_name
            ?? $notifiable->name
            ?? 'Tenant';

        if ($this->kind === 'lease_expiry' && $this->subject instanceof Contract) {
            $end = optional($this->subject->end_date)->toFormattedDateString() ?? 'N/A';
            $number = $this->subject->contract_number;

            return (new MailMessage)
                ->subject('Lease expiry reminder')
                ->greeting('Hello '.$name.',')
                ->line("Your lease {$number} is approaching expiry.")
                ->line("End date: {$end}")
                ->line('Please contact property management if you wish to renew.')
                ->salutation('Grids Property Management');
        }

        /** @var Payment $payment */
        $payment = $this->subject;
        $status = $payment->status;
        $amount = $payment->amount;
        $due = optional($payment->due_date)->toFormattedDateString() ?? 'N/A';
        $period = $payment->period ?? 'current period';
        $subject = $status === 'overdue'
            ? 'Overdue rent payment reminder'
            : 'Upcoming rent payment reminder';

        return (new MailMessage)
            ->subject($subject)
            ->greeting('Hello '.$name.',')
            ->line("This is an automated reminder for your rent payment ({$period}).")
            ->line("Amount: {$amount}")
            ->line("Due date: {$due}")
            ->line('Status: '.ucfirst((string) $status))
            ->line('Please pay on time to avoid late fees.')
            ->salutation('Grids Property Management');
    }
}
