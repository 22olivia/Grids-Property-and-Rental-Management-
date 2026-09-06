<?php

namespace App\Jobs;

use App\Services\EmailService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

class RetryFailedEmailsJob implements ShouldQueue
{
    use Queueable;

    public function handle(EmailService $emails): void
    {
        $emails->retryFailed();
    }
}
