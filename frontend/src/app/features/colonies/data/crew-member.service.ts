import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';

import { APP_CONFIG } from '../../../core/config/app-config';

/** Values of `ck_crew_status`, mirrored by the backend `CrewStatus` enum (ARES-103). */
export const CREW_STATUSES = [
  'ACTIVE',
  'OFF_DUTY',
  'TRAINING',
  'MEDICAL_LEAVE',
  'SUSPENDED',
  'INACTIVE',
] as const;

export type CrewStatus = (typeof CREW_STATUSES)[number];

export const CREW_STATUS_LABELS: Record<CrewStatus, string> = {
  ACTIVE: 'Active',
  OFF_DUTY: 'Off duty',
  TRAINING: 'Training',
  MEDICAL_LEAVE: 'Medical leave',
  SUSPENDED: 'Suspended',
  INACTIVE: 'Inactive',
};

/** A crew member as returned by `/crew-members`. */
export interface CrewMember {
  readonly employeeCode: string;
  readonly firstName: string;
  readonly lastName: string;
  readonly email: string | null;
  readonly operationalRole: string;
  readonly status: CrewStatus;
  readonly homeColonyCode: string | null;
}

/** Body of `POST /crew-members`. */
export interface NewCrewMember {
  readonly employeeCode: string;
  readonly firstName: string;
  readonly lastName: string;
  readonly email: string | null;
  readonly operationalRole: string;
  readonly status: CrewStatus;
  readonly homeColonyCode: string | null;
}

/** Stable backend codes of the crew domain (ADR-0005). */
export const CrewErrorCode = {
  CREW_MEMBER_CODE_TAKEN: 'CREW_MEMBER_CODE_TAKEN',
  PERSON_EMAIL_TAKEN: 'PERSON_EMAIL_TAKEN',
  HOME_COLONY_NOT_FOUND: 'HOME_COLONY_NOT_FOUND',
  HOME_COLONY_INACTIVE: 'HOME_COLONY_INACTIVE',
} as const;

@Injectable({ providedIn: 'root' })
export class CrewMemberService {
  private readonly http = inject(HttpClient);
  private readonly config = inject(APP_CONFIG);

  private get url(): string {
    return `${this.config.apiBaseUrl}/crew-members`;
  }

  /** Every crew member, ordered by employee code. */
  list(): Observable<CrewMember[]> {
    return this.http.get<CrewMember[]>(this.url);
  }

  /** Registers a crew member; the server normalises the code and email. */
  create(member: NewCrewMember): Observable<CrewMember> {
    return this.http.post<CrewMember>(this.url, member);
  }
}
