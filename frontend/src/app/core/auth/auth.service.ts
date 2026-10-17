import { HttpClient } from '@angular/common/http';
import { Injectable, computed, inject, signal } from '@angular/core';
import { Observable, catchError, map, of, switchMap, tap } from 'rxjs';

import { APP_CONFIG } from '../config/app-config';

/** `GET /auth/session` (ADR-0012): who is signed in and what they may do. */
export interface Session {
  readonly authenticated: boolean;
  readonly username: string | null;
  readonly displayName: string | null;
  readonly roles: readonly string[];
  readonly permissions: readonly string[];
}

export const ANONYMOUS: Session = {
  authenticated: false,
  username: null,
  displayName: null,
  roles: [],
  permissions: [],
};

/** Permission codes the UI checks (backend `permission` table). */
export type Permission =
  'COLONY_READ' | 'CREW_READ' | 'CREW_MANAGE' | 'MISSION_READ' | 'MISSION_MANAGE';

/**
 * The signed-in user, kept in a signal. The session itself is an HttpOnly cookie the browser
 * sends; the CSRF cookie set by `GET /auth/session` is echoed by Angular's XSRF support.
 * Permissions only shape the UI: the server checks every request (IAM-005).
 */
@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly http = inject(HttpClient);
  private readonly baseUrl = `${inject(APP_CONFIG).apiBaseUrl}/auth`;
  private readonly current = signal<Session>(ANONYMOUS);

  readonly session = this.current.asReadonly();
  readonly authenticated = computed(() => this.current().authenticated);

  hasPermission(permission: Permission): boolean {
    return this.current().permissions.includes(permission);
  }

  /** Asks the server who is signed in; anonymous when it cannot tell. Never errors. */
  refresh(): Observable<Session> {
    return this.http.get<Session>(`${this.baseUrl}/session`).pipe(
      catchError(() => of(ANONYMOUS)),
      tap((session) => this.current.set(session)),
    );
  }

  /** Errors with the server's response when the credentials are refused. */
  login(username: string, password: string): Observable<Session> {
    // the session call first, so that the CSRF cookie exists even after a logout or expiry
    return this.http.get<Session>(`${this.baseUrl}/session`).pipe(
      switchMap(() => this.http.post<Session>(`${this.baseUrl}/login`, { username, password })),
      tap((session) => this.current.set(session)),
    );
  }

  /** Ends the session on the server; the local state is cleared whatever the answer. */
  logout(): Observable<void> {
    return this.http.post<void>(`${this.baseUrl}/logout`, null).pipe(
      catchError(() => of(undefined)),
      map(() => this.expire()),
    );
  }

  /** Forgets the user locally, e.g. when the server answers 401 because the session expired. */
  expire(): void {
    this.current.set(ANONYMOUS);
  }
}
