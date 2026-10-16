import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable, catchError, map, of } from 'rxjs';

import { APP_CONFIG } from '../config/app-config';

/** `up`: healthy · `down`: reachable but unhealthy · `unreachable`: no answer from the server. */
export type BackendHealth = 'up' | 'down' | 'unreachable';

/** Status codes meaning nobody answered behind a proxy/gateway (dev proxy, reverse proxy). */
const GATEWAY_ERRORS = new Set([0, 502, 504]);

interface ActuatorHealth {
  readonly status?: string;
}

@Injectable({ providedIn: 'root' })
export class BackendHealthService {
  private readonly http = inject(HttpClient);
  private readonly config = inject(APP_CONFIG);

  /** Emits once and completes; never errors. */
  check(): Observable<BackendHealth> {
    return this.http.get<ActuatorHealth>(this.config.healthUrl).pipe(
      map((body): BackendHealth => (body?.status === 'UP' ? 'up' : 'down')),
      catchError((error: unknown) =>
        of<BackendHealth>(
          error instanceof HttpErrorResponse && !GATEWAY_ERRORS.has(error.status)
            ? 'down'
            : 'unreachable',
        ),
      ),
    );
  }
}
