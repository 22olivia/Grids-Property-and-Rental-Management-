<?php

use App\Jobs\RunRentalAutomationJob;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

/*
|--------------------------------------------------------------------------
| SRS §19 – documented scheduler for billing + reminders
|--------------------------------------------------------------------------
| Production requires a process that runs either:
|   php artisan schedule:work
| or cron: * * * * * php artisan schedule:run
|
| Plus a queue worker for notifications/jobs:
|   php artisan queue:work --sleep=1 --tries=3
*/
Schedule::job(new RunRentalAutomationJob)
    ->dailyAt('06:00')
    ->name('rental-daily-automation')
    ->withoutOverlapping();
