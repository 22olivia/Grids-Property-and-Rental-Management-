<?php

namespace App\Jobs;

use App\Services\RentalAutomationService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

class SendRentRemindersJob implements ShouldQueue
{
    use Queueable;

    public function handle(RentalAutomationService $automation): void
    {
        $automation->sendPaymentReminders();
    }
}
