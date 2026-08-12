'use client';

import { activeDataSource } from '@/lib/data/repository';
import type { AssetRepository } from './asset-repository';
import { mockAssetRepository } from './mock-asset-repository';
import { browserAssetRepository } from './browser-asset-repository';

/**
 * Asset data binding — the only module that genuinely switches.
 *
 * `http` routes through the BFF to the real Laravel API; the contract for
 * properties, buildings and rental units is verified. `mock` runs the UI with
 * no backend, which is what makes an offline demo possible.
 */
export const ASSETS_ARE_MOCK = activeDataSource() !== 'http';

export const assetRepository: AssetRepository = ASSETS_ARE_MOCK
  ? mockAssetRepository
  : browserAssetRepository;

export type { AssetRepository } from './asset-repository';
