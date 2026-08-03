<?php

namespace App\Jobs;

use App\Services\RentalAutomationService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

/**
 * Queued daily automation bundle (SRS recurring billing + reminders).
 */
class RunRentalAutomationJob implements ShouldQueue
{
    use Queueable;

    public function handle(RentalAutomationService $automation): void
    {
        $automation->run();
    }
}
