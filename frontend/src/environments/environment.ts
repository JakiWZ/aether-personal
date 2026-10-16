import { AppConfig } from '../app/core/config/app-config';

// Production build. The SPA is served from the same origin as the API (reverse proxy), so URLs are
// relative. Point them elsewhere here, never in components.
export const environment: AppConfig = {
  production: true,
  apiBaseUrl: '/api/v1',
  healthUrl: '/actuator/health',
};
