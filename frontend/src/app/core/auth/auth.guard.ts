import { inject } from '@angular/core';
import { CanMatchFn, Router, UrlSegment } from '@angular/router';

import { AuthService, Permission } from './auth.service';

/** Feature routes need a session; otherwise the login page, then back to where the user was going. */
export const authGuard: CanMatchFn = (_route, segments: UrlSegment[]) => {
  if (inject(AuthService).authenticated()) {
    return true;
  }
  const returnUrl = '/' + segments.map((s) => s.path).join('/');
  return inject(Router).createUrlTree(['/login'], { queryParams: { returnUrl } });
};

/**
 * Hides a page the user has no permission for, sending them to `fallback` instead. The server
 * refuses the request anyway; this only avoids showing a form that cannot be submitted.
 */
export function permissionGuard(permission: Permission, fallback: string): CanMatchFn {
  return () => inject(AuthService).hasPermission(permission) || inject(Router).parseUrl(fallback);
}

/**
 * Where to go after login: only a path inside this application, never `//host` or a full URL
 * (OWASP unvalidated redirects).
 */
export function safeReturnUrl(candidate: string | null | undefined): string {
  if (
    !candidate ||
    !candidate.startsWith('/') ||
    candidate.startsWith('//') ||
    candidate.includes('\\')
  ) {
    return '/dashboard';
  }
  return candidate.startsWith('/login') ? '/dashboard' : candidate;
}
