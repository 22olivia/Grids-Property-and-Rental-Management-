<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Jobs\RunRentalAutomationJob;
use App\Services\RentalAutomationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AutomationController extends Controller
{
    /**
     * Run automation.
     * - sync=1 (default for demo): run immediately and return counts
     * - sync=0: queue job for worker (cloud / other devices)
     */
    public function run(Request $request, RentalAutomationService $automation): JsonResponse
    {
        $sync = $request->boolean('sync', true);

        if (! $sync) {
            RunRentalAutomationJob::dispatch();

            return response()->json([
                'message' => 'Automation queued for background processing.',
                'data' => [
                    'queued' => true,
                    'queue' => config('queue.default'),
                ],
            ], 202);
        }

        $summary = $automation->run();

        return response()->json([
            'message' => 'Automation completed.',
            'data' => $summary,
        ]);
    }
}
