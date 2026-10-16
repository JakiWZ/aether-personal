import { InjectionToken, Provider } from '@angular/core';

/**
 * Runtime configuration of the SPA. Values come from `src/environments/*` and are injected via
 * {@link APP_CONFIG}; components and services never hardcode backend URLs (NFR-008).
 */
export interface AppConfig {
  /** True for production builds. */
  readonly production: boolean;
  /** Base URL of the REST API, e.g. `/api/v1` (same origin) or `https://api.example.org/api/v1`. */
  readonly apiBaseUrl: string;
  /** URL of the backend health endpoint (Spring Boot Actuator). */
  readonly healthUrl: string;
}

export const APP_CONFIG = new InjectionToken<AppConfig>('APP_CONFIG');

export function provideAppConfig(config: AppConfig): Provider {
  return { provide: APP_CONFIG, useValue: config };
}
