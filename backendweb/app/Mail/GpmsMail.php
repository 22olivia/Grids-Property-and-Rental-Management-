<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class GpmsMail extends Mailable
{
    use Queueable, SerializesModels;

    /**
     * @param  array{subject: string, heading: string, body_html: string}  $payload
     */
    public function __construct(public array $payload) {}

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: $this->payload['subject'],
        );
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.gpms',
            with: [
                'subject' => $this->payload['subject'],
                'heading' => $this->payload['heading'],
                'bodyHtml' => $this->payload['body_html'],
            ],
        );
    }
}
