import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';

import { APP_CONFIG } from '../../../core/config/app-config';

/** Values of `ck_mission_status`; new missions are always DRAFT (PHX-201). */
export const MISSION_STATUSES = [
  'DRAFT',
  'PLANNED',
  'APPROVAL_PENDING',
  'APPROVED',
  'IN_PROGRESS',
  'COMPLETED',
  'ABORTED',
  'CANCELLED',
] as const;
export type MissionStatus = (typeof MISSION_STATUSES)[number];

export const MISSION_STATUS_LABELS: Record<MissionStatus, string> = {
  DRAFT: 'Draft',
  PLANNED: 'Planned',
  APPROVAL_PENDING: 'Approval pending',
  APPROVED: 'Approved',
  IN_PROGRESS: 'In progress',
  COMPLETED: 'Completed',
  ABORTED: 'Aborted',
  CANCELLED: 'Cancelled',
};

/** Values of `ck_mission_type`. */
export const MISSION_TYPES = [
  'INTERNAL',
  'EVA',
  'SCIENCE',
  'LOGISTICS',
  'MAINTENANCE',
  'RESCUE',
  'INSPECTION',
  'EXPLORATION',
  'TRANSPORT',
] as const;
export type MissionType = (typeof MISSION_TYPES)[number];

export const MISSION_TYPE_LABELS: Record<MissionType, string> = {
  INTERNAL: 'Internal',
  EVA: 'EVA',
  SCIENCE: 'Science',
  LOGISTICS: 'Logistics',
  MAINTENANCE: 'Maintenance',
  RESCUE: 'Rescue',
  INSPECTION: 'Inspection',
  EXPLORATION: 'Exploration',
  TRANSPORT: 'Transport',
};

/** Values of `ck_mission_priority`, lowest first. */
export const MISSION_PRIORITIES = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'] as const;
export type MissionPriority = (typeof MISSION_PRIORITIES)[number];

export const MISSION_PRIORITY_LABELS: Record<MissionPriority, string> = {
  LOW: 'Low',
  MEDIUM: 'Medium',
  HIGH: 'High',
  CRITICAL: 'Critical',
};

/** Risk levels (`ck_mission_safety`), lowest first. */
export const SAFETY_LEVELS = ['STANDARD', 'ELEVATED', 'HIGH_RISK', 'CRITICAL'] as const;
export type SafetyLevel = (typeof SAFETY_LEVELS)[number];

export const SAFETY_LEVEL_LABELS: Record<SafetyLevel, string> = {
  STANDARD: 'Standard',
  ELEVATED: 'Elevated',
  HIGH_RISK: 'High risk',
  CRITICAL: 'Critical',
};

/** A mission as returned by `/missions`. Instants are ISO-8601 with offset (BR-011). */
export interface Mission {
  readonly code: string;
  readonly title: string;
  readonly description: string | null;
  readonly objectives: readonly string[];
  readonly type: MissionType;
  readonly originColonyCode: string;
  readonly plannedStartAt: string;
  readonly plannedEndAt: string;
  readonly status: MissionStatus;
  readonly priority: MissionPriority;
  readonly safetyLevel: SafetyLevel;
  readonly createdBy: string;
  readonly createdAt: string;
}

/** Body of `POST /missions`; the server sets the status. */
export interface NewMission {
  readonly code: string;
  readonly title: string;
  readonly description: string | null;
  readonly objective: string;
  readonly type: MissionType;
  readonly originColonyCode: string;
  readonly plannedStartAt: string;
  readonly plannedEndAt: string;
  readonly priority: MissionPriority;
  readonly safetyLevel: SafetyLevel;
}

/** Stable backend codes of the missions domain (ADR-0005). */
export const MissionErrorCode = {
  MISSION_CODE_TAKEN: 'MISSION_CODE_TAKEN',
  ORIGIN_COLONY_NOT_FOUND: 'ORIGIN_COLONY_NOT_FOUND',
  ORIGIN_COLONY_INACTIVE: 'ORIGIN_COLONY_INACTIVE',
} as const;

@Injectable({ providedIn: 'root' })
export class MissionService {
  private readonly http = inject(HttpClient);
  private readonly config = inject(APP_CONFIG);

  private get url(): string {
    return `${this.config.apiBaseUrl}/missions`;
  }

  /** Every mission, ordered by planned start. */
  list(): Observable<Mission[]> {
    return this.http.get<Mission[]>(this.url);
  }

  /** Drafts a mission; the server normalises the code and assigns status DRAFT. */
  create(mission: NewMission): Observable<Mission> {
    return this.http.post<Mission>(this.url, mission);
  }
}
