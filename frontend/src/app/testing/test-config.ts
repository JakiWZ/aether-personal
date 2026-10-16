import { AppConfig, provideAppConfig } from '../core/config/app-config';
import { Page } from '../core/http/page';

/** A backend URL no component could have hardcoded: tests prove the configured URL is used. */
export const TEST_CONFIG: AppConfig = {
  production: false,
  apiBaseUrl: 'http://backend.test/api/v1',
  healthUrl: 'http://backend.test/actuator/health',
};

export const provideTestConfig = () => provideAppConfig(TEST_CONFIG);

/** Wraps items in the page envelope of the list endpoints (ADR-0011). */
export function pageOf<T>(
  items: readonly T[],
  page = 0,
  size = 20,
  totalItems = items.length,
): Page<T> {
  return { items, page, size, totalItems, totalPages: Math.ceil(totalItems / size) };
}
