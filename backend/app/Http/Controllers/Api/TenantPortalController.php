<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Contract;
use App\Models\Invoice;
use App\Models\Payment;
use App\Models\PaymentOrder;
use App\Models\Receipt;
use App\Models\Tenant;
use App\Models\TenantDocument;
use App\Services\ActivityLogger;
use App\Services\Payments\PaymentOrderService;
use App\Support\Roles;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Crypt;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class TenantPortalController extends Controller
{
    private function tenantOrFail(Request $request): Tenant
    {
        abort_unless($request->user()?->normalizedRole() === Roles::TENANT, 403, 'Tenant access only.');
        $tenant = $request->user()->tenant;
        abort_unless($tenant, 404, 'Tenant profile not found.');

        return $tenant;
    }

    private function activeLease(Tenant $tenant): ?Contract
    {
        return Contract::query()
            ->with(['rentalUnit.property', 'tenant'])
            ->where('tenant_id', $tenant->id)
            ->whereIn('status', ['active', 'expiring_soon', 'renewed', 'pending_signature', 'notice_given'])
            ->latest()
            ->first();
    }

    public function lease(Request $request): JsonResponse
    {
        $tenant = $this->tenantOrFail($request);
        $lease = $this->activeLease($tenant);
        abort_unless($lease, 404, 'No lease found for this tenant.');

        $unit = $lease->rentalUnit;
        $property = $unit?->property;

        return response()->json([
            'data' => [
                'id' => $lease->id,
                'lease_number' => $lease->contract_number,
                'contract_number' => $lease->contract_number,
                'status' => $lease->status,
                'property' => [
                    'id' => $property?->id,
                    'name' => $property?->name,
                    'address' => trim(($property?->address_line1 ?: '').', '.($property?->city ?: '')),
                ],
                'building' => $unit?->building?->name,
                'floor' => $unit?->floorLevel?->name ?: $unit?->floor,
                'unit' => $unit?->unit_number,
                'unit_number' => $unit?->unit_number,
                'organisation' => $request->user()->organization?->name,
                'landlord' => $property?->owner?->full_name,
                'property_manager' => [
                    'id' => $unit?->assigned_manager_id,
                    'name' => $unit?->assignedManager?->name,
                    'email' => $unit?->assignedManager?->email,
                    'phone' => $unit?->assignedManager?->phone,
                ],
                'tenant_names' => array_filter([$tenant->full_name]),
                'start_date' => optional($lease->start_date)?->toDateString(),
                'end_date' => optional($lease->end_date)?->toDateString(),
                'monthly_rent' => $lease->monthly_rent,
                'maintenance_charge' => $unit?->maintenance_charge,
                'security_deposit' => $lease->deposit_amount,
                'deposit_amount' => $lease->deposit_amount,
                'rent_due_day' => 5,
                'notice_period_days' => 60,
                'lock_in_period_months' => 6,
                'escalation_percentage' => '5.00',
                'grace_period_days' => 5,
                'late_fee_policy' => 'Late fee applies after grace period per organisation policy.',
                'utilities_responsibility' => 'As per lease agreement',
                'parking_details' => null,
                'occupant_limit' => $unit?->tenant_capacity,
                'special_conditions' => $lease->notes,
                'renewal_status' => in_array($lease->status, ['expiring_soon'], true) ? 'eligible' : 'active',
                'days_remaining' => $lease->end_date
                    ? now()->startOfDay()->diffInDays($lease->end_date->startOfDay(), false)
                    : null,
                'timeline' => [
                    ['event' => 'Lease started', 'date' => optional($lease->start_date)?->toDateString(), 'status' => 'completed'],
                    ['event' => 'Lease ends', 'date' => optional($lease->end_date)?->toDateString(), 'status' => 'upcoming'],
                ],
                'amendments' => $lease->amendments()->latest()->get(['id', 'title', 'summary', 'effective_date']),
                'history' => [],
                'rental_unit' => $unit,
                'tenant' => ['full_name' => $tenant->full_name, 'email' => $tenant->email],
            ],
        ]);
    }

    public function signLease(Request $request, ActivityLogger $logger): JsonResponse
    {
        $tenant = $this->tenantOrFail($request);
        $lease = $this->activeLease($tenant);
        abort_unless($lease, 404);
        abort_unless($lease->status === 'pending_signature', 422, 'Lease is not pending signature.');

        $lease->update(['status' => 'active']);
        $logger->log('tenant.lease.signed', $lease, ['tenant_id' => $tenant->id], $request);

        return $this->lease($request);
    }

    public function requestRenewal(Request $request, ActivityLogger $logger): JsonResponse
    {
        $tenant = $this->tenantOrFail($request);
        $lease = $this->activeLease($tenant);
        abort_unless($lease, 404);
        $logger->log('tenant.lease.renewal_requested', $lease, ['tenant_id' => $tenant->id], $request);

        return response()->json([
            'message' => 'Renewal request submitted for manager review.',
            'data' => ['renewal_status' => 'requested'],
        ]);
    }

    public function submitNotice(Request $request, ActivityLogger $logger): JsonResponse
    {
        $tenant = $this->tenantOrFail($request);
        $lease = $this->activeLease($tenant);
        abort_unless($lease, 404);
        $lease->update(['status' => 'notice_given']);
        $logger->log('tenant.lease.notice_submitted', $lease, ['tenant_id' => $tenant->id], $request);

        return response()->json([
            'message' => 'Move-out notice submitted.',
            'data' => ['status' => 'notice_given'],
        ]);
    }

    public function receipts(Request $request): JsonResponse
    {
        $tenant = $this->tenantOrFail($request);
        $rows = Receipt::query()
            ->where('tenant_id', $tenant->id)
            ->latest('payment_date')
            ->get();

        if ($rows->isEmpty()) {
            $leaseIds = Contract::query()->where('tenant_id', $tenant->id)->pluck('id');
            $rows = Payment::query()
                ->whereIn('contract_id', $leaseIds)
                ->where('status', 'paid')
                ->latest('paid_at')
                ->get()
                ->map(fn (Payment $payment) => [
                    'id' => $payment->id,
                    'receipt_number' => $payment->transaction_number ?: 'RCP-'.$payment->id,
                    'payment_date' => optional($payment->paid_at)?->toDateString(),
                    'tenant_name' => $tenant->full_name,
                    'property' => null,
                    'unit' => null,
                    'billing_period' => $payment->period,
                    'amount_paid' => $payment->amount,
                    'payment_method' => $payment->method,
                    'transaction_reference' => $payment->reference ?: $payment->transaction_number,
                    'invoice_number' => optional($payment->invoice)->invoice_number,
                    'payment_id' => $payment->id,
                ]);
        }

        return response()->json(['data' => $rows, 'total' => count($rows)]);
    }

    public function documents(Request $request): JsonResponse
    {
        $tenant = $this->tenantOrFail($request);
        $query = TenantDocument::query()->where('tenant_id', $tenant->id);
        if ($category = $request->string('category')->toString()) {
            $query->where('category', $category);
        }

        $rows = $query->latest()->get()->map(fn (TenantDocument $doc) => [
            'id' => $doc->id,
            'title' => $doc->title,
            'category' => $doc->category,
            'uploaded_date' => optional($doc->created_at)?->toDateString(),
            'expiry_date' => optional($doc->expiry_date)?->toDateString(),
            'verification_status' => $doc->verification_status,
            'file_type' => $doc->file_type,
            'file_size' => $this->humanSize((int) $doc->file_size),
            'can_delete' => (bool) $doc->tenant_owned,
            'download_url' => "/api/v1/tenant/documents/{$doc->id}/download",
        ]);

        return response()->json(['data' => $rows, 'total' => $rows->count()]);
    }

    public function uploadDocument(Request $request, ActivityLogger $logger): JsonResponse
    {
        $tenant = $this->tenantOrFail($request);
        $validated = $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'category' => ['required', 'string', 'max:80'],
            'file_type' => ['nullable', 'string', 'max:40'],
            'file_size' => ['nullable', 'string'],
            'path' => ['nullable', 'string'],
        ]);

        $doc = TenantDocument::query()->create([
            'organization_id' => $request->user()->organization_id,
            'tenant_id' => $tenant->id,
            'uploaded_by' => $request->user()->id,
            'title' => $validated['title'],
            'category' => $validated['category'],
            'path' => $validated['path'] ?? 'tenant-docs/'.Str::uuid().'.pdf',
            'file_type' => $validated['file_type'] ?? 'pdf',
            'file_size' => 120000,
            'verification_status' => 'pending',
            'tenant_owned' => true,
        ]);

        $logger->log('tenant.document.uploaded', $doc, ['tenant_id' => $tenant->id], $request);

        return response()->json(['message' => 'Document uploaded.', 'data' => $doc], 201);
    }

    public function deleteDocument(Request $request, TenantDocument $document, ActivityLogger $logger): JsonResponse
    {
        $tenant = $this->tenantOrFail($request);
        abort_unless($document->tenant_id === $tenant->id, 403);
        abort_unless($document->tenant_owned, 403, 'Only tenant-uploaded documents can be deleted.');
        $document->delete();
        $logger->log('tenant.document.deleted', $document, ['tenant_id' => $tenant->id], $request);

        return response()->json(['message' => 'Document deleted.']);
    }

    public function downloadDocument(Request $request, TenantDocument $document): JsonResponse
    {
        $tenant = $this->tenantOrFail($request);
        abort_unless($document->tenant_id === $tenant->id, 403);

        try {
            $url = Storage::disk($document->disk ?: 'local')->temporaryUrl(
                $document->path,
                now()->addMinutes(10),
            );
        } catch (\Throwable) {
            $url = url("/api/v1/tenant/documents/{$document->id}/download").'?expires='.now()->addMinutes(10)->timestamp.'&signature='.hash_hmac('sha256', (string) $document->id, (string) config('app.key'));
        }

        return response()->json([
            'data' => [
                'url' => $url,
                'expires_in' => 600,
                'note' => 'Signed URL — private storage.',
            ],
        ]);
    }

    public function calendar(Request $request, \App\Services\TenantCalendarService $calendar): JsonResponse
    {
        $tenant = $this->tenantOrFail($request);
        $events = $calendar->eventsFor($tenant);

        return response()->json(['data' => $events, 'total' => count($events)]);
    }

    public function profile(Request $request): JsonResponse
    {
        $tenant = $this->tenantOrFail($request);
        $masked = null;
        if ($tenant->identity_number_encrypted) {
            try {
                $raw = Crypt::decryptString($tenant->identity_number_encrypted);
                $masked = Str::mask($raw, '*', 3, max(strlen($raw) - 5, 0));
            } catch (\Throwable) {
                $masked = '****';
            }
        }

        return response()->json([
            'data' => [
                'id' => $tenant->id,
                'user_id' => $tenant->user_id,
                'full_name' => $tenant->full_name,
                'email' => $tenant->email,
                'phone' => $tenant->phone,
                'alternate_phone' => $tenant->alternate_phone,
                'date_of_birth' => optional($tenant->date_of_birth)?->toDateString(),
                'occupation' => $tenant->occupation,
                'employer' => $tenant->employer,
                'emergency_contact' => is_string($tenant->emergency_contact)
                    ? ['name' => $tenant->emergency_contact, 'phone' => '', 'relation' => '']
                    : $tenant->emergency_contact,
                'communication_address' => $tenant->communication_address,
                'preferred_language' => $tenant->preferred_language ?: 'en',
                'profile_completion' => $tenant->profile_completion ?: 70,
                'identity' => [
                    'type' => $tenant->identity_type,
                    'number_masked' => $masked,
                    'verification_status' => $tenant->identity_verification_status,
                    'expiry_date' => optional($tenant->identity_expiry_date)?->toDateString(),
                ],
            ],
        ]);
    }

    public function updateProfile(Request $request, ActivityLogger $logger): JsonResponse
    {
        $tenant = $this->tenantOrFail($request);

        $validated = $request->validate([
            'full_name' => ['sometimes', 'string', 'max:255'],
            'email' => ['sometimes', 'email', 'max:255'],
            'phone' => ['nullable', 'string', 'max:40'],
            'occupation' => ['nullable', 'string', 'max:255'],
            'employer' => ['nullable', 'string', 'max:255'],
            'alternate_phone' => ['nullable', 'string', 'max:40'],
            'communication_address' => ['nullable', 'string'],
            'preferred_language' => ['nullable', 'string', 'max:10'],
            'emergency_contact' => ['nullable', 'array'],
        ]);

        $tenant->fill($validated);
        if (isset($validated['emergency_contact'])) {
            $tenant->emergency_contact = json_encode($validated['emergency_contact']);
        }
        $tenant->save();

        $user = $request->user();
        if ($user) {
            if (! empty($validated['email'])) {
                $user->email = $validated['email'];
            }
            if (array_key_exists('phone', $validated)) {
                $user->phone = $validated['phone'];
            }
            if (! empty($validated['full_name'])) {
                $user->name = $validated['full_name'];
            }
            $user->save();
        }

        $logger->log('tenant.profile.updated', $tenant, [], $request);

        return $this->profile($request);
    }

    public function settings(Request $request): JsonResponse
    {
        $tenant = $this->tenantOrFail($request);
        $defaults = [
            'account' => [
                'language' => $tenant->preferred_language ?: 'en',
                'timezone' => 'Asia/Dubai',
                'date_format' => 'DD/MM/YYYY',
                'currency_display' => 'AED',
                'theme' => 'system',
            ],
            'notification_preferences' => [
                'rent_reminders' => ['in_app' => true, 'email' => true, 'sms' => true, 'whatsapp' => true, 'push' => true],
                'payment_updates' => ['in_app' => true, 'email' => true, 'sms' => false, 'whatsapp' => true, 'push' => true],
                'lease_updates' => ['in_app' => true, 'email' => true, 'sms' => false, 'whatsapp' => false, 'push' => true],
                'maintenance_updates' => ['in_app' => true, 'email' => true, 'sms' => true, 'whatsapp' => true, 'push' => true],
                'announcements' => ['in_app' => true, 'email' => true, 'sms' => false, 'whatsapp' => false, 'push' => false],
                'promotional' => ['in_app' => false, 'email' => false, 'sms' => false, 'whatsapp' => false, 'push' => false],
            ],
            'security' => [
                'two_factor_enabled' => false,
                'active_sessions' => [],
            ],
            'privacy' => [
                'communication_consent' => true,
                'consents' => [],
            ],
        ];

        return response()->json([
            'data' => array_replace_recursive($defaults, $tenant->settings ?: []),
        ]);
    }

    public function updateSettings(Request $request, ActivityLogger $logger): JsonResponse
    {
        $tenant = $this->tenantOrFail($request);
        $tenant->settings = $request->all();
        $tenant->save();
        $logger->log('tenant.settings.updated', $tenant, [], $request);

        return $this->settings($request);
    }

    public function search(Request $request): JsonResponse
    {
        $tenant = $this->tenantOrFail($request);
        $q = strtolower($request->string('q')->toString());
        if (strlen($q) < 2) {
            return response()->json(['data' => []]);
        }

        $leaseIds = Contract::query()->where('tenant_id', $tenant->id)->pluck('id');
        $hits = [];

        Invoice::query()
            ->whereIn('contract_id', $leaseIds)
            ->where(function ($query) use ($q) {
                $query->whereRaw('LOWER(invoice_number) like ?', ["%{$q}%"])
                    ->orWhereRaw('LOWER(status) like ?', ["%{$q}%"]);
            })
            ->limit(5)
            ->get()
            ->each(function (Invoice $invoice) use (&$hits) {
                $hits[] = [
                    'type' => 'invoice',
                    'title' => $invoice->invoice_number,
                    'subtitle' => $invoice->status,
                    'href' => "/invoices/{$invoice->id}",
                ];
            });

        Payment::query()
            ->whereIn('contract_id', $leaseIds)
            ->limit(5)
            ->get()
            ->filter(fn (Payment $p) => str_contains(strtolower(($p->transaction_number ?: '').' '.$p->status), $q))
            ->each(function (Payment $payment) use (&$hits) {
                $hits[] = [
                    'type' => 'payment',
                    'title' => $payment->transaction_number ?: 'Payment '.$payment->id,
                    'subtitle' => (string) $payment->amount,
                    'href' => "/payments/{$payment->id}/receipt",
                ];
            });

        return response()->json(['data' => array_slice($hits, 0, 12)]);
    }

    public function paymentSummary(Request $request): JsonResponse
    {
        $tenant = $this->tenantOrFail($request);
        $leaseIds = Contract::query()->where('tenant_id', $tenant->id)->pluck('id');
        $payments = Payment::query()->whereIn('contract_id', $leaseIds)->where('status', 'paid');
        $outstanding = Invoice::query()
            ->whereIn('contract_id', $leaseIds)
            ->whereIn('status', ['unpaid', 'partially_paid', 'overdue', 'pending'])
            ->sum('remaining_balance');
        $last = (clone $payments)->latest('paid_at')->first();
        $next = Invoice::query()
            ->whereIn('contract_id', $leaseIds)
            ->whereIn('status', ['unpaid', 'partially_paid', 'overdue', 'pending'])
            ->orderBy('due_date')
            ->first();

        return response()->json([
            'data' => [
                'total_paid' => number_format((float) $payments->sum('amount'), 2, '.', ''),
                'outstanding_amount' => number_format((float) $outstanding, 2, '.', ''),
                'last_payment' => $last,
                'next_due_date' => optional($next?->due_date)?->toDateString(),
                'methods' => [
                    'upi',
                    'card',
                    'emi',
                    'net_banking',
                    'bank_transfer',
                    'wallet',
                    'cash',
                    'cheque',
                    'apple_pay',
                    'google_pay',
                ],
            ],
        ]);
    }

    public function createPaymentOrder(Request $request, PaymentOrderService $orders): JsonResponse
    {
        $tenant = $this->tenantOrFail($request);
        $validated = $request->validate([
            'invoice_ids' => ['required', 'array', 'min:1'],
            'invoice_ids.*' => ['integer'],
            'amount' => ['required', 'numeric', 'min:0.01'],
            'method' => ['required', 'string', 'in:'.implode(',', Payment::METHODS)],
            'emi_months' => ['nullable', 'integer', 'in:3,6,9,12'],
            'idempotency_key' => ['nullable', 'string', 'max:120'],
        ]);

        $order = $orders->createOrder(
            $tenant,
            $validated['invoice_ids'],
            (float) $validated['amount'],
            $validated['method'],
            $validated['emi_months'] ?? null,
            $validated['idempotency_key'] ?? $request->header('Idempotency-Key'),
            $request->user(),
        );

        return response()->json([
            'message' => 'Payment order created. Complete checkout, then confirm or wait for webhook capture.',
            'data' => $order->toApiArray(),
        ], 201);
    }

    public function showPaymentOrder(Request $request, string $order): JsonResponse
    {
        $tenant = $this->tenantOrFail($request);
        $row = PaymentOrder::query()
            ->where('tenant_id', $tenant->id)
            ->where(function ($q) use ($order) {
                $q->where('order_number', $order)->orWhere('id', $order);
            })
            ->firstOrFail();

        return response()->json(['data' => $row->toApiArray()]);
    }

    public function confirmPaymentOrder(Request $request, string $order, PaymentOrderService $orders): JsonResponse
    {
        $tenant = $this->tenantOrFail($request);
        $validated = $request->validate([
            'checkout_token' => ['required', 'string'],
            'transaction_id' => ['nullable', 'string', 'max:120'],
            'payment_instrument' => ['nullable', 'array'],
            'payment_instrument.type' => ['nullable', 'string', 'max:40'],
            'payment_instrument.brand' => ['nullable', 'string', 'max:40'],
            'payment_instrument.last4' => ['nullable', 'string', 'max:4'],
            'payment_instrument.vpa_masked' => ['nullable', 'string', 'max:80'],
            'payment_instrument.bank' => ['nullable', 'string', 'max:80'],
            'payment_instrument.channel' => ['nullable', 'string', 'max:40'],
            'payment_instrument.demo_token' => ['nullable', 'string', 'max:120'],
        ]);

        $row = PaymentOrder::query()
            ->where('tenant_id', $tenant->id)
            ->where('order_number', $order)
            ->firstOrFail();

        if (! empty($validated['payment_instrument'])) {
            $instrument = collect($validated['payment_instrument'])
                ->only(['type', 'brand', 'last4', 'vpa_masked', 'bank', 'channel', 'demo_token'])
                ->filter(fn ($value) => filled($value))
                ->all();
            $meta = is_array($row->meta) ? $row->meta : [];
            $meta['payment_instrument'] = $instrument;
            $row->update(['meta' => $meta]);
        }

        $captured = $orders->confirmDemoOrder(
            $row->fresh(),
            $validated['checkout_token'],
            $validated['transaction_id'] ?? null,
        );

        $receiptNumber = $captured->meta['receipt_number']
            ?? Receipt::query()->where('payment_id', $captured->payment_id)->value('receipt_number');

        return response()->json([
            'message' => 'Payment captured successfully.',
            'data' => array_merge($captured->toApiArray(), [
                'receipt_number' => $receiptNumber,
                'status' => 'successful',
            ]),
        ]);
    }

    public function paymentWebhook(Request $request, PaymentOrderService $orders, ?string $provider = null): JsonResponse
    {
        $provider = $provider ?: (string) $request->input('provider', config('payments.default', 'demo'));
        $result = $orders->handleWebhook(
            $provider,
            $request->getContent() ?: json_encode($request->all()) ?: '{}',
            $request->headers->all(),
            $request->all(),
        );

        $status = ($result['ok'] ?? false) ? 200 : 400;

        return response()->json([
            'message' => $result['message'] ?? 'Webhook processed.',
            'verified' => (bool) ($result['verified'] ?? false),
            'data' => $result['data'] ?? null,
            'duplicate' => $result['duplicate'] ?? false,
        ], $status);
    }

    private function humanSize(int $bytes): string
    {
        if ($bytes < 1024) {
            return $bytes.' B';
        }
        if ($bytes < 1048576) {
            return round($bytes / 1024).' KB';
        }

        return round($bytes / 1048576, 1).' MB';
    }
}
