<?php

namespace App\Console\Commands;

use App\Services\RentalAutomationService;
use Illuminate\Console\Command;

class RunRentalAutomation extends Command
{
    protected $signature = 'rental:automate';

    protected $description = 'Generate due rent, mark overdue payments, and log reminders';

    public function handle(RentalAutomationService $automation): int
    {
        $summary = $automation->run();

        $this->info('Rental automation complete.');
        $this->table(
            ['Metric', 'Count'],
            [
                ['Generated payments', $summary['generated_payments']],
                ['Marked overdue', $summary['marked_overdue']],
                ['Reminders', $summary['reminders']],
                ['Expiring leases (30d)', $summary['expiring_leases']],
            ]
        );

        return self::SUCCESS;
    }
}
