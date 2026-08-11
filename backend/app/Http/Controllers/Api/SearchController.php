<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Invoice;
use App\Models\Organization;
use App\Models\Payment;
use App\Models\Property;
use App\Models\RentalUnit;
use App\Models\Tenant;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SearchController extends Controller
{
    public function __invoke(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'q' => ['nullable', 'string', 'max:100'],
        ]);
        $term = trim($validated['q'] ?? '');

        if ($term === '') {
            return response()->json(['data' => []]);
        }

        $user = $request->user();
        $organizationId = $user->organization_id;
        $like = '%'.$term.'%';
        $scopeOrganization = function (Builder $query, string $column = 'organization_id') use ($user, $organizationId): void {
            if (! $user->isSuperAdmin()) {
                $organizationId
                    ? $query->where($column, $organizationId)
                    : $query->whereRaw('1 = 0');
            }
        };

        $results = collect();

        $organizations = Organization::query()
            ->where('name', 'like', $like)
            ->tap(fn (Builder $query) => $scopeOrganization($query, 'id'))
            ->limit(5)
            ->get(['id', 'name', 'city', 'country']);
        $results->push(...$organizations->map(fn (Organization $organization) => [
            'type' => 'Organisation',
            'title' => $organization->name,
            'subtitle' => collect([$organization->city, $organization->country])->filter()->join(', ') ?: 'Organisation',
            'href' => '/organizations',
        ]));

        $properties = Property::query()
            ->where('name', 'like', $like)
            ->tap(fn (Builder $query) => $scopeOrganization($query))
            ->limit(5)
            ->get(['id', 'name', 'city']);
        $results->push(...$properties->map(fn (Property $property) => [
            'type' => 'Property',
            'title' => $property->name,
            'subtitle' => $property->city ?: 'Property',
            'href' => '/properties',
        ]));

        $tenants = Tenant::query()
            ->where(fn (Builder $query) => $query
                ->where('full_name', 'like', $like)
                ->orWhere('email', 'like', $like))
            ->when(! $user->isSuperAdmin(), function (Builder $query) use ($organizationId): void {
                $organizationId
                    ? $query->whereHas('contracts.rentalUnit', fn (Builder $units) => $units->where('organization_id', $organizationId))
                    : $query->whereRaw('1 = 0');
            })
            ->limit(5)
            ->get(['id', 'full_name', 'email']);
        $results->push(...$tenants->map(fn (Tenant $tenant) => [
            'type' => 'Tenant',
            'title' => $tenant->full_name,
            'subtitle' => $tenant->email ?: 'Tenant',
            'href' => "/tenants/{$tenant->id}",
        ]));

        $invoices = Invoice::query()
            ->where('invoice_number', 'like', $like)
            ->when(! $user->isSuperAdmin(), function (Builder $query) use ($organizationId): void {
                $organizationId
                    ? $query->whereHas('contract.rentalUnit', fn (Builder $units) => $units->where('organization_id', $organizationId))
                    : $query->whereRaw('1 = 0');
            })
            ->limit(5)
            ->get(['id', 'invoice_number', 'status']);
        $results->push(...$invoices->map(fn (Invoice $invoice) => [
            'type' => 'Invoice',
            'title' => $invoice->invoice_number,
            'subtitle' => ucfirst(str_replace('_', ' ', $invoice->status)),
            'href' => "/invoices/{$invoice->id}",
        ]));

        $payments = Payment::query()
            ->where('transaction_number', 'like', $like)
            ->when(! $user->isSuperAdmin(), function (Builder $query) use ($organizationId): void {
                $organizationId
                    ? $query->whereHas('contract.rentalUnit', fn (Builder $units) => $units->where('organization_id', $organizationId))
                    : $query->whereRaw('1 = 0');
            })
            ->limit(5)
            ->get(['id', 'transaction_number', 'status']);
        $results->push(...$payments->map(fn (Payment $payment) => [
            'type' => 'Payment',
            'title' => $payment->transaction_number,
            'subtitle' => ucfirst(str_replace('_', ' ', $payment->status)),
            'href' => '/payments',
        ]));

        $units = RentalUnit::query()
            ->with('property:id,name')
            ->where('unit_number', 'like', $like)
            ->tap(fn (Builder $query) => $scopeOrganization($query))
            ->limit(5)
            ->get(['id', 'property_id', 'unit_number', 'status']);
        $results->push(...$units->map(fn (RentalUnit $unit) => [
            'type' => 'Rental unit',
            'title' => "Unit {$unit->unit_number}",
            'subtitle' => collect([$unit->property?->name, ucfirst($unit->status)])->filter()->join(' · '),
            'href' => "/units/{$unit->id}",
        ]));

        return response()->json(['data' => $results->take(30)->values()]);
    }
}
