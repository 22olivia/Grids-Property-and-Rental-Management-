<?php

namespace App\Jobs;

use App\Models\EmailLog;
use App\Services\EmailService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

class SendQueuedEmailJob implements ShouldQueue
{
    use Queueable;

    public int $tries = 5;

    public function __construct(public readonly int $emailLogId) {}

    public function handle(EmailService $emails): void
    {
        $log = EmailLog::query()->find($this->emailLogId);
        if (! $log) {
            return;
        }

        $emails->deliver($log);
    }
}
