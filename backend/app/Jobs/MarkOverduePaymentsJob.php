<?php

namespace App\Jobs;

use App\Services\RentalAutomationService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

class MarkOverduePaymentsJob implements ShouldQueue
{
    use Queueable;

    public function handle(RentalAutomationService $automation): void
    {
        $automation->markOverduePayments();
    }
}
