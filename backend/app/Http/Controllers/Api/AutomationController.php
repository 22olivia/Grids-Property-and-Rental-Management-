<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\RentalAutomationService;
use Illuminate\Http\JsonResponse;

class AutomationController extends Controller
{
    public function run(RentalAutomationService $automation): JsonResponse
    {
        $summary = $automation->run();

        return response()->json([
            'message' => 'Automation completed.',
            'data' => $summary,
        ]);
    }
}
