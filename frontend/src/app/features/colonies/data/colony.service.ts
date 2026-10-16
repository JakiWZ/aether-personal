import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';

import { APP_CONFIG } from '../../../core/config/app-config';

/** Values of `ck_colony_status`, mirrored by the backend `ColonyStatus` enum. */
export type ColonyStatus =
  'PLANNED' | 'CONSTRUCTION' | 'OPERATIONAL' | 'DEGRADED' | 'EMERGENCY' | 'INACTIVE';

/** A Martian base as returned by `GET /colonies` (ARES-101). */
export interface Colony {
  readonly code: string;
  readonly name: string;
  readonly status: ColonyStatus;
  /** False for bases taken out of operation; their history is kept (BR-010). */
  readonly active: boolean;
  readonly maxPopulation: number | null;
  /** ISO date (`yyyy-MM-dd`). */
  readonly establishedAt: string | null;
}

@Injectable({ providedIn: 'root' })
export class ColonyService {
  private readonly http = inject(HttpClient);
  private readonly config = inject(APP_CONFIG);

  /** Lists the bases ordered by code; `active` keeps only active (`true`) or inactive (`false`) ones. */
  list(active?: boolean): Observable<Colony[]> {
    const params = active === undefined ? undefined : new HttpParams().set('active', active);
    return this.http.get<Colony[]>(`${this.config.apiBaseUrl}/colonies`, { params });
  }
}
