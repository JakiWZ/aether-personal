import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';

import { APP_CONFIG } from '../../../core/config/app-config';
import { DEFAULT_PAGE_SIZE, MAX_PAGE_SIZE, Page, withPage } from '../../../core/http/page';

/** Values of `ck_resource_category`, mirrored by the backend `ResourceCategory` enum (ORI-401). */
export const RESOURCE_CATEGORIES = [
  'LIFE_SUPPORT',
  'FOOD',
  'FUEL',
  'SPARE_PART',
  'MEDICAL',
  'SCIENTIFIC',
  'OTHER',
] as const;
export type ResourceCategory = (typeof RESOURCE_CATEGORIES)[number];

export const RESOURCE_CATEGORY_LABELS: Record<ResourceCategory, string> = {
  LIFE_SUPPORT: 'Life support',
  FOOD: 'Food',
  FUEL: 'Fuel',
  SPARE_PART: 'Spare part',
  MEDICAL: 'Medical',
  SCIENTIFIC: 'Scientific',
  OTHER: 'Other',
};

/** A consumable resource as returned by `/resources`. */
export interface Resource {
  readonly code: string;
  readonly name: string;
  readonly category: ResourceCategory;
  readonly unitCode: string;
  readonly unitSymbol: string;
  /** True when running out endangers the crew. */
  readonly critical: boolean;
  /** False for resources taken out of use; their history is kept (BR-010). */
  readonly active: boolean;
  readonly shelfLifeDays: number | null;
}

/** Body of `POST /resources`; the server creates it active. */
export interface NewResource {
  readonly code: string;
  readonly name: string;
  readonly category: ResourceCategory;
  readonly unitCode: string;
  readonly critical: boolean;
  readonly shelfLifeDays: number | null;
}

/** A unit of measure as returned by `/units-of-measure`. */
export interface UnitOfMeasure {
  readonly code: string;
  readonly name: string;
  readonly symbol: string;
  readonly quantityType: string;
}

/** Stable backend codes of the inventory domain (ADR-0005). */
export const InventoryErrorCode = {
  RESOURCE_CODE_TAKEN: 'RESOURCE_CODE_TAKEN',
  UNIT_OF_MEASURE_NOT_FOUND: 'UNIT_OF_MEASURE_NOT_FOUND',
} as const;

@Injectable({ providedIn: 'root' })
export class ResourceService {
  private readonly http = inject(HttpClient);
  private readonly config = inject(APP_CONFIG);

  private get url(): string {
    return `${this.config.apiBaseUrl}/resources`;
  }

  /** One page of resources ordered by code; `active` keeps only active (`true`) or inactive (`false`) ones. */
  list(active?: boolean, page = 0, size = DEFAULT_PAGE_SIZE): Observable<Page<Resource>> {
    let params = withPage(new HttpParams(), page, size);
    if (active !== undefined) {
      params = params.set('active', active);
    }
    return this.http.get<Page<Resource>>(this.url, { params });
  }

  /** Adds a resource; the server normalises the codes. */
  create(resource: NewResource): Observable<Resource> {
    return this.http.post<Resource>(this.url, resource);
  }

  /** Activates or deactivates a resource; nothing is ever deleted. */
  setActive(code: string, active: boolean): Observable<Resource> {
    return this.http.patch<Resource>(`${this.url}/${encodeURIComponent(code)}`, { active });
  }

  /** Every unit of measure (the reference list fits in one page). */
  units(): Observable<Page<UnitOfMeasure>> {
    return this.http.get<Page<UnitOfMeasure>>(`${this.config.apiBaseUrl}/units-of-measure`, {
      params: withPage(new HttpParams(), 0, MAX_PAGE_SIZE),
    });
  }
}
