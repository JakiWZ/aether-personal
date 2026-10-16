import { AppConfig, provideAppConfig } from '../core/config/app-config';

/** A backend URL no component could have hardcoded: tests prove the configured URL is used. */
export const TEST_CONFIG: AppConfig = {
  production: false,
  apiBaseUrl: 'http://backend.test/api/v1',
  healthUrl: 'http://backend.test/actuator/health',
};

export const provideTestConfig = () => provideAppConfig(TEST_CONFIG);
