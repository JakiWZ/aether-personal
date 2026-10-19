import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';

import { APP_CONFIG } from '../../../core/config/app-config';
import { DEFAULT_PAGE_SIZE, Page, withPage } from '../../../core/http/page';

/** Values of `ck_incident_severity`, lowest first, mirrored by the backend `IncidentSeverity`. */
export const INCIDENT_SEVERITIES = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'] as const;
export type IncidentSeverity = (typeof INCIDENT_SEVERITIES)[number];

export const INCIDENT_SEVERITY_LABELS: Record<IncidentSeverity, string> = {
  LOW: 'Low',
  MEDIUM: 'Medium',
  HIGH: 'High',
  CRITICAL: 'Critical',
};

/** What each severity means; shown next to the choice so reporters pick consistently. */
export const INCIDENT_SEVERITY_HINTS: Record<IncidentSeverity, string> = {
  LOW: 'no impact on safety or operations',
  MEDIUM: 'degraded operations, no danger for the crew',
  HIGH: 'operations or crew at risk',
  CRITICAL: 'immediate danger for the crew or the base',
};

/** Values of `ck_incident_status`; a new incident is always OPEN (HEL-501). */
export type IncidentStatus =
  'OPEN' | 'ACKNOWLEDGED' | 'IN_PROGRESS' | 'RESOLVED' | 'CLOSED' | 'CANCELLED';

export const INCIDENT_STATUS_LABELS: Record<IncidentStatus, string> = {
  OPEN: 'Open',
  ACKNOWLEDGED: 'Acknowledged',
  IN_PROGRESS: 'In progress',
  RESOLVED: 'Resolved',
  CLOSED: 'Closed',
  CANCELLED: 'Cancelled',
};

/** An incident as returned by `/incidents`. `openedAt` is ISO-8601 with offset (BR-011). */
export interface Incident {
  readonly code: string;
  readonly title: string;
  readonly description: string;
  readonly severity: IncidentSeverity;
  readonly status: IncidentStatus;
  readonly colonyCode: string;
  readonly reportedBy: string;
  readonly openedAt: string;
}

/** Body of `POST /incidents`; code, status, reporter and time are set by the server. */
export interface NewIncident {
  readonly colonyCode: string;
  readonly title: string;
  readonly description: string;
  readonly severity: IncidentSeverity;
}

/** Stable backend codes of the incidents domain (ADR-0005). */
export const IncidentErrorCode = {
  INCIDENT_COLONY_NOT_FOUND: 'INCIDENT_COLONY_NOT_FOUND',
} as const;

@Injectable({ providedIn: 'root' })
export class IncidentService {
  private readonly http = inject(HttpClient);
  private readonly config = inject(APP_CONFIG);

  private get url(): string {
    return `${this.config.apiBaseUrl}/incidents`;
  }

  /** One page of incidents, newest first. */
  list(page = 0, size = DEFAULT_PAGE_SIZE): Observable<Page<Incident>> {
    return this.http.get<Page<Incident>>(this.url, {
      params: withPage(new HttpParams(), page, size),
    });
  }

  /** Opens an incident; the server answers with its code and status OPEN. */
  open(incident: NewIncident): Observable<Incident> {
    return this.http.post<Incident>(this.url, incident);
  }
}
