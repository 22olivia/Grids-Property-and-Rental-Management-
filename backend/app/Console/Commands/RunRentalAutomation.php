<?php

namespace App\Console\Commands;

use App\Jobs\RunRentalAutomationJob;
use App\Services\RentalAutomationService;
use Illuminate\Console\Command;

class RunRentalAutomation extends Command
{
    protected $signature = 'rental:automate {--queue : Dispatch to the queue instead of running inline}';

    protected $description = 'Generate due rent, mark overdue payments, and send reminders (SRS automation)';

    public function handle(RentalAutomationService $automation): int
    {
        if ($this->option('queue')) {
            RunRentalAutomationJob::dispatch();
            $this->info('Automation job queued ('.config('queue.default').').');

            return self::SUCCESS;
        }

        $summary = $automation->run();

        $this->info('Rental automation complete.');
        $this->table(
            ['Metric', 'Count'],
            [
                ['Generated payments', $summary['generated_payments']],
                ['Marked overdue', $summary['marked_overdue']],
                ['Rent reminders', $summary['reminders']],
                ['Expiry reminders', $summary['expiry_reminders']],
                ['Expiring leases (30d)', $summary['expiring_leases']],
            ]
        );

        return self::SUCCESS;
    }
}
