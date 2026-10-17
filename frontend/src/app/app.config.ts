import { provideHttpClient, withFetch, withInterceptors } from '@angular/common/http';
import {
  ApplicationConfig,
  inject,
  provideAppInitializer,
  provideBrowserGlobalErrorListeners,
} from '@angular/core';
import { TitleStrategy, provideRouter, withComponentInputBinding } from '@angular/router';
import { firstValueFrom } from 'rxjs';

import { environment } from '../environments/environment';
import { routes } from './app.routes';
import { authInterceptor } from './core/auth/auth.interceptor';
import { AuthService } from './core/auth/auth.service';
import { provideAppConfig } from './core/config/app-config';
import { AetherTitleStrategy } from './core/navigation/aether-title-strategy';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideRouter(routes, withComponentInputBinding()),
    // Angular's XSRF support (on by default) echoes the XSRF-TOKEN cookie as X-XSRF-TOKEN on
    // same-origin writes, which is what Spring Security expects (ADR-0012).
    provideHttpClient(withFetch(), withInterceptors([authInterceptor])),
    provideAppConfig(environment),
    { provide: TitleStrategy, useClass: AetherTitleStrategy },
    // Know who is signed in before the first route is matched.
    provideAppInitializer(() => firstValueFrom(inject(AuthService).refresh())),
  ],
};
