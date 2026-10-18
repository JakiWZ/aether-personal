import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';

import { APP_CONFIG } from '../../../core/config/app-config';
import { DEFAULT_PAGE_SIZE, Page, withPage } from '../../../core/http/page';

/** Values of `ck_asset_status`, mirrored by the backend `AssetStatus` enum. */
export const VEHICLE_STATUSES = [
  'AVAILABLE',
  'IN_USE',
  'MAINTENANCE',
  'OUT_OF_SERVICE',
  'DECOMMISSIONED',
] as const;
export type VehicleStatus = (typeof VEHICLE_STATUSES)[number];

export const VEHICLE_STATUS_LABELS: Record<VehicleStatus, string> = {
  AVAILABLE: 'Available',
  IN_USE: 'In use',
  MAINTENANCE: 'Maintenance',
  OUT_OF_SERVICE: 'Out of service',
  DECOMMISSIONED: 'Decommissioned',
};

/** Values of `ck_asset_criticality`, lowest first. */
export type Criticality = 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';

export const CRITICALITY_LABELS: Record<Criticality, string> = {
  LOW: 'Low',
  MEDIUM: 'Medium',
  HIGH: 'High',
  CRITICAL: 'Critical',
};

/** A rover, drone or shuttle as returned by `GET /vehicles` (TIT-301). */
export interface Vehicle {
  readonly code: string;
  readonly typeCode: string;
  readonly typeName: string;
  readonly manufacturer: string | null;
  readonly model: string | null;
  readonly serialNumber: string | null;
  readonly status: VehicleStatus;
  readonly criticality: Criticality;
  /** Base where the vehicle is stationed. */
  readonly colonyCode: string;
  /** False for vehicles taken out of the fleet; their history is kept (BR-010). */
  readonly active: boolean;
  /** ISO date (`yyyy-MM-dd`). */
  readonly commissionedAt: string | null;
  readonly operatingHours: number;
}

@Injectable({ providedIn: 'root' })
export class VehicleService {
  private readonly http = inject(HttpClient);
  private readonly config = inject(APP_CONFIG);

  /** One page of vehicles ordered by code; `status` keeps only the vehicles in that status. */
  list(status?: VehicleStatus, page = 0, size = DEFAULT_PAGE_SIZE): Observable<Page<Vehicle>> {
    let params = withPage(new HttpParams(), page, size);
    if (status !== undefined) {
      params = params.set('status', status);
    }
    return this.http.get<Page<Vehicle>>(`${this.config.apiBaseUrl}/vehicles`, { params });
  }
}
