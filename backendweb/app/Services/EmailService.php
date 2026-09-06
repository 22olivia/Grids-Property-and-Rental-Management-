<?php

namespace App\Services;

use App\Jobs\SendQueuedEmailJob;
use App\Mail\GpmsMail;
use App\Models\EmailLog;
use App\Models\EmailOtp;
use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;

class EmailService
{
    /**
     * @param  array<string, mixed>  $variables
     */
    public function queue(
        string $templateKey,
        string $toEmail,
        array $variables = [],
        ?string $toName = null,
        ?User $user = null,
        ?Model $related = null,
        ?int $organizationId = null,
    ): EmailLog {
        $rendered = $this->renderTemplate($templateKey, $variables);
        $provider = $this->provider();

        $log = EmailLog::query()->create([
            'organization_id' => $organizationId ?? $user?->organization_id,
            'user_id' => $user?->id,
            'related_type' => $related ? $related::class : null,
            'related_id' => $related?->getKey(),
            'template_key' => $templateKey,
            'to_email' => $toEmail,
            'to_name' => $toName,
            'subject' => $rendered['subject'],
            'payload' => [
                'heading' => $rendered['heading'],
                'body_html' => $rendered['body_html'],
                'variables' => $variables,
            ],
            'provider' => $provider,
            'status' => 'queued',
            'attempts' => 0,
        ]);

        // Always deliver inline. Railway free tier usually has no queue worker, so
        // dispatch-only left ticket emails stuck as "queued" and never sent.
        try {
            $this->deliver($log);
        } catch (\Throwable $e) {
            report($e);
            try {
                SendQueuedEmailJob::dispatch($log->id);
            } catch (\Throwable $e2) {
                report($e2);
            }
        }

        return $log->fresh() ?? $log;
    }

    /**
     * Queue a free-form notification-centre email (subject/body already rendered).
     *
     * @param  array<string, mixed>  $extraPayload
     */
    public function queueNotification(
        string $toEmail,
        string $subject,
        string $heading,
        string $bodyHtml,
        ?string $toName = null,
        ?User $user = null,
        ?Model $related = null,
        ?int $organizationId = null,
        array $extraPayload = [],
    ): EmailLog {
        $provider = $this->provider();

        $log = EmailLog::query()->create([
            'organization_id' => $organizationId ?? $user?->organization_id,
            'user_id' => $user?->id,
            'related_type' => $related ? $related::class : null,
            'related_id' => $related?->getKey(),
            'template_key' => 'notification_centre',
            'to_email' => $toEmail,
            'to_name' => $toName,
            'subject' => $subject,
            'payload' => array_merge([
                'heading' => $heading,
                'body_html' => $bodyHtml,
            ], $extraPayload),
            'provider' => $provider,
            'status' => 'queued',
            'attempts' => 0,
        ]);

        // Deliver immediately for notification centre so delivery logs reflect
        // the real SMTP/log outcome in the same request/job cycle.
        $this->deliver($log);

        return $log->fresh() ?? $log;
    }

    public function deliver(EmailLog $log): void
    {
        if (in_array($log->status, ['sent'], true)) {
            return;
        }

        // Common Railway misconfig: MAIL_HOST/USERNAME set but MAIL_MAILER left as "log".
        $defaultMailer = (string) config('mail.default', 'log');
        $smtpHost = (string) config('mail.mailers.smtp.host', '');
        $smtpUser = (string) config('mail.mailers.smtp.username', '');
        if (
            in_array($defaultMailer, ['log', 'array'], true)
            && $smtpHost !== ''
            && $smtpHost !== '127.0.0.1'
            && $smtpUser !== ''
        ) {
            config(['mail.default' => 'smtp']);
        }

        $log->attempts++;
        try {
            $payload = $log->payload ?? [];
            Mail::to([
                [
                    'email' => $log->to_email,
                    'name' => $log->to_name ?: $log->to_email,
                ],
            ])->send(new GpmsMail([
                'subject' => $log->subject,
                'heading' => (string) ($payload['heading'] ?? 'GPMS'),
                'body_html' => (string) ($payload['body_html'] ?? ''),
            ]));

            $mailer = (string) config('mail.default', 'log');
            $simulated = in_array($mailer, ['log', 'array'], true);

            $log->forceFill([
                'status' => 'sent',
                'provider' => $simulated ? 'log' : $this->provider(),
                'provider_message_id' => strtoupper($log->provider ?: 'SMTP').'-'.Str::upper(Str::random(10)),
                'provider_response' => [
                    'ok' => true,
                    'provider' => $mailer,
                    'simulated' => $simulated,
                ],
                'error_message' => null,
                'next_retry_at' => null,
                'sent_at' => now(),
            ])->save();
        } catch (\Throwable $e) {
            $log->forceFill([
                'status' => $log->attempts >= 5 ? 'failed' : 'retrying',
                'error_message' => $e->getMessage(),
                'next_retry_at' => now()->addMinutes(min(60, 2 ** $log->attempts)),
                'provider_response' => ['ok' => false, 'error' => $e->getMessage()],
            ])->save();
        }
    }

    public function retryFailed(): int
    {
        $rows = EmailLog::query()
            ->whereIn('status', ['failed', 'retrying', 'queued'])
            ->where(function ($q) {
                $q->whereNull('next_retry_at')->orWhere('next_retry_at', '<=', now());
            })
            ->where('attempts', '<', 5)
            ->limit(100)
            ->get();

        foreach ($rows as $log) {
            SendQueuedEmailJob::dispatch($log->id);
        }

        return $rows->count();
    }

    /**
     * Send and store a one-time password.
     *
     * @return array{otp: EmailOtp, plain_code: string, email_log: EmailLog}
     */
    public function sendOtp(
        string $email,
        string $purpose,
        ?User $user = null,
        ?string $ip = null,
    ): array {
        $code = (string) random_int(100000, 999999);

        EmailOtp::query()
            ->where('email', $email)
            ->where('purpose', $purpose)
            ->whereNull('consumed_at')
            ->update(['consumed_at' => now()]);

        $otp = EmailOtp::query()->create([
            'user_id' => $user?->id,
            'email' => $email,
            'purpose' => $purpose,
            'code_hash' => Hash::make($code),
            'expires_at' => now()->addMinutes(10),
            'ip_address' => $ip,
        ]);

        $log = $this->queue(
            'otp',
            $email,
            [
                'user_name' => $user?->name ?: 'there',
                'otp_code' => $code,
                'purpose' => str_replace('_', ' ', $purpose),
                'expires_minutes' => '10',
            ],
            $user?->name,
            $user,
            $otp,
        );

        return ['otp' => $otp, 'plain_code' => $code, 'email_log' => $log];
    }

    public function verifyOtp(string $email, string $purpose, string $code): bool
    {
        $otp = EmailOtp::query()
            ->where('email', $email)
            ->where('purpose', $purpose)
            ->whereNull('consumed_at')
            ->where('expires_at', '>', now())
            ->latest()
            ->first();

        if (! $otp) {
            return false;
        }

        $otp->attempts++;
        if ($otp->attempts > 5) {
            $otp->consumed_at = now();
            $otp->save();

            return false;
        }

        if (! Hash::check($code, $otp->code_hash)) {
            $otp->save();

            return false;
        }

        $otp->forceFill(['consumed_at' => now()])->save();

        return true;
    }

    /**
     * @param  array<string, mixed>  $variables
     * @return array{subject: string, heading: string, body_html: string}
     */
    public function renderTemplate(string $templateKey, array $variables = []): array
    {
        $templates = $this->templates();
        $template = $templates[$templateKey] ?? $templates['general_announcement'];
        $vars = array_merge([
            'user_name' => 'there',
            'recipient_name' => 'there',
            'organisation_name' => 'GPMS',
            'property_name' => '—',
            'unit_number' => '—',
            'ticket_number' => '—',
            'category' => '—',
            'priority' => '—',
            'message' => '',
            'date' => now()->toDayDateTimeString(),
            'dashboard_link' => rtrim((string) config('app.url'), '/').'/help-support',
            'action_link' => rtrim((string) config('app.url'), '/'),
            'otp_code' => '******',
            'invoice_number' => '—',
            'amount' => '—',
            'due_date' => '—',
            'lease_number' => '—',
            'purpose' => 'verification',
            'expires_minutes' => '10',
        ], $variables);

        return [
            'subject' => $this->interpolate($template['subject'], $vars),
            'heading' => $this->interpolate($template['heading'], $vars),
            'body_html' => $this->interpolate($template['body_html'], $vars),
        ];
    }

    /**
     * @return array<string, array{subject: string, heading: string, body_html: string}>
     */
    private function templates(): array
    {
        return [
            'otp' => [
                'subject' => '[GPMS] Your verification code',
                'heading' => 'One-time password',
                'body_html' => '<p>Hello {{user_name}},</p><p>Your {{purpose}} code is:</p><p style="font-size:28px;font-weight:700;letter-spacing:0.2em;">{{otp_code}}</p><p>This code expires in {{expires_minutes}} minutes.</p>',
            ],
            'welcome' => [
                'subject' => 'Welcome to GPMS',
                'heading' => 'Welcome',
                'body_html' => '<p>Hello {{user_name}},</p><p>Your GPMS account is ready. Sign in to manage properties, leases, and payments.</p><p><a href="{{action_link}}/login">Open GPMS</a></p>',
            ],
            'password_reset' => [
                'subject' => '[GPMS] Reset your password',
                'heading' => 'Password reset',
                'body_html' => '<p>Hello {{user_name}},</p><p>Use this link to reset your password:</p><p><a href="{{action_link}}">Reset password</a></p><p>If you did not request this, you can ignore this email.</p>',
            ],
            'support_ticket_staff' => [
                'subject' => '[GPMS] Support Ticket #{{ticket_number}}',
                'heading' => 'New support request',
                'body_html' => '<p>Hello {{recipient_name}},</p><p>A new support request has been submitted.</p><p><strong>Ticket Number:</strong> {{ticket_number}}<br><strong>User:</strong> {{user_name}}<br><strong>Property:</strong> {{property_name}}<br><strong>Unit:</strong> {{unit_number}}<br><strong>Category:</strong> {{category}}<br><strong>Priority:</strong> {{priority}}</p><p><strong>Message:</strong><br>{{message}}</p><p><strong>Submitted On:</strong> {{date}}</p><p><a href="{{dashboard_link}}">Open Ticket</a></p><p>Regards,<br>GPMS</p>',
            ],
            'support_ticket_user' => [
                'subject' => "We've received your support request",
                'heading' => 'Request received',
                'body_html' => '<p>Hello {{user_name}},</p><p>Your request has been received successfully.</p><p><strong>Ticket Number:</strong> {{ticket_number}}<br><strong>Category:</strong> {{category}}</p><p>Our team will review your request shortly.</p><p>You can track its status from:<br>Dashboard → Help &amp; Support</p><p>Thank you.</p>',
            ],
            'support_reply' => [
                'subject' => '[GPMS] Reply on Ticket #{{ticket_number}}',
                'heading' => 'New reply',
                'body_html' => '<p>Hello {{user_name}},</p><p>There is a new reply on ticket <strong>{{ticket_number}}</strong>.</p><p>{{message}}</p><p><a href="{{dashboard_link}}">View ticket</a></p>',
            ],
            'contact_owner' => [
                'subject' => '[GPMS] Contact Owner — Ticket #{{ticket_number}}',
                'heading' => 'Contact Property Owner',
                'body_html' => '<p>Hello {{recipient_name}},</p><p>{{user_name}} contacted the property owner.</p><p><strong>Ticket:</strong> {{ticket_number}}<br><strong>Property:</strong> {{property_name}} · {{unit_number}}</p><p>{{message}}</p><p><a href="{{dashboard_link}}">Open ticket</a></p>',
            ],
            'contact_manager' => [
                'subject' => '[GPMS] Contact Manager — Ticket #{{ticket_number}}',
                'heading' => 'Contact Property Manager',
                'body_html' => '<p>Hello {{recipient_name}},</p><p>{{user_name}} contacted the property manager.</p><p><strong>Ticket:</strong> {{ticket_number}}<br><strong>Property:</strong> {{property_name}} · {{unit_number}}</p><p>{{message}}</p><p><a href="{{dashboard_link}}">Open ticket</a></p>',
            ],
            'contact_support' => [
                'subject' => '[GPMS] Platform Support — Ticket #{{ticket_number}}',
                'heading' => 'Platform Support',
                'body_html' => '<p>Hello {{recipient_name}},</p><p>A platform support request needs attention.</p><p><strong>Ticket:</strong> {{ticket_number}}<br><strong>User:</strong> {{user_name}}<br><strong>Category:</strong> {{category}} · {{priority}}</p><p>{{message}}</p><p><a href="{{dashboard_link}}">Open ticket</a></p>',
            ],
            'maintenance_update' => [
                'subject' => '[GPMS] Maintenance update — {{ticket_number}}',
                'heading' => 'Maintenance update',
                'body_html' => '<p>Hello {{user_name}},</p><p>Maintenance ticket {{ticket_number}} for {{property_name}} {{unit_number}} was updated.</p><p>{{message}}</p>',
            ],
            'invoice_notification' => [
                'subject' => '[GPMS] Invoice {{invoice_number}}',
                'heading' => 'Invoice notice',
                'body_html' => '<p>Hello {{user_name}},</p><p>Invoice <strong>{{invoice_number}}</strong> for {{amount}} is due on {{due_date}}.</p><p><a href="{{action_link}}/invoices">View invoices</a></p>',
            ],
            'lease_notification' => [
                'subject' => '[GPMS] Lease update — {{lease_number}}',
                'heading' => 'Lease update',
                'body_html' => '<p>Hello {{user_name}},</p><p>Lease <strong>{{lease_number}}</strong> for {{property_name}} {{unit_number}} has an update.</p><p>{{message}}</p>',
            ],
            'general_announcement' => [
                'subject' => '[GPMS] {{subject_line}}',
                'heading' => 'Announcement',
                'body_html' => '<p>Hello {{user_name}},</p><p>{{message}}</p>',
            ],
        ];
    }

    /**
     * @param  array<string, mixed>  $variables
     */
    private function interpolate(string $body, array $variables): string
    {
        return preg_replace_callback('/\{\{\s*([a-zA-Z0-9_]+)\s*\}\}/', function ($matches) use ($variables) {
            return e((string) ($variables[$matches[1]] ?? ''));
        }, $body) ?? $body;
    }

    private function provider(): string
    {
        $mailer = (string) config('mail.default', 'log');

        return match ($mailer) {
            'resend' => 'resend',
            'smtp' => env('MAIL_HOST') === 'smtp-relay.brevo.com' ? 'brevo' : 'smtp',
            'array' => 'array',
            default => $mailer ?: 'log',
        };
    }
}
