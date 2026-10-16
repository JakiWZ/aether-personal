import { HttpParams } from '@angular/common/http';

/** One page of a list endpoint, as returned by the backend `PageResponse` (ADR-0011). */
export interface Page<T> {
  readonly items: readonly T[];
  /** Zero-based page index. */
  readonly page: number;
  readonly size: number;
  readonly totalItems: number;
  readonly totalPages: number;
}

/** Default page size of the backend. */
export const DEFAULT_PAGE_SIZE = 20;

/** Largest page the backend serves; asking for more is a 400. */
export const MAX_PAGE_SIZE = 100;

/** Adds `page` and `size` to the query parameters of a list request. */
export function withPage(params: HttpParams, page: number, size: number): HttpParams {
  return params.set('page', page).set('size', size);
}
