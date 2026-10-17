import { HttpTestingController } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';

import { AuthService, Session } from '../core/auth/auth.service';
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

/** A signed-in user with every permission the UI checks. */
export const SIGNED_IN: Session = {
  authenticated: true,
  username: 'mc.rossi',
  displayName: 'Laura Rossi',
  roles: ['MISSION_CONTROLLER'],
  permissions: ['COLONY_READ', 'CREW_READ', 'CREW_MANAGE', 'MISSION_READ', 'MISSION_MANAGE'],
};

/** Signs in through the real `AuthService`, answering its session request with `session`. */
export function signIn(session: Session = SIGNED_IN): void {
  TestBed.inject(AuthService).refresh().subscribe();
  TestBed.inject(HttpTestingController)
    .expectOne(`${TEST_CONFIG.apiBaseUrl}/auth/session`)
    .flush(session);
}
