import { AppConfig } from '../app/core/config/app-config';

// `ng serve`: requests to /api and /actuator are forwarded to the backend by proxy.conf.json,
// so the browser sees a single origin and no CORS configuration is needed locally.
export const environment: AppConfig = {
  production: false,
  apiBaseUrl: '/api/v1',
  healthUrl: '/actuator/health',
};
