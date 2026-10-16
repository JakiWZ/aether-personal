import { NgTemplateOutlet } from '@angular/common';
import { ChangeDetectionStrategy, Component, DestroyRef, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import {
  AbstractControl,
  NonNullableFormBuilder,
  ReactiveFormsModule,
  ValidationErrors,
  ValidatorFn,
  Validators,
} from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';

import { ApiError, toApiError } from '../../../core/http/api-error';
import { MAX_PAGE_SIZE } from '../../../core/http/page';
import { Colony, ColonyService } from '../../colonies/data/colony.service';
import {
  MISSION_PRIORITIES,
  MISSION_PRIORITY_LABELS,
  MISSION_TYPES,
  MISSION_TYPE_LABELS,
  MissionErrorCode,
  MissionPriority,
  MissionService,
  MissionType,
  SAFETY_LEVELS,
  SAFETY_LEVEL_LABELS,
  SafetyLevel,
} from '../data/mission.service';

/** Mirrors the backend pattern; the server stays authoritative. */
const MISSION_CODE_PATTERN = /^[A-Za-z0-9][A-Za-z0-9-]{2,59}$/;

type FormField =
  | 'code'
  | 'title'
  | 'objective'
  | 'description'
  | 'type'
  | 'originColonyCode'
  | 'plannedStartAt'
  | 'plannedEndAt'
  | 'priority'
  | 'safetyLevel';

/** Backend codes that belong to one field rather than to the whole form. */
const FIELD_OF_CODE: Partial<Record<string, FormField>> = {
  [MissionErrorCode.MISSION_CODE_TAKEN]: 'code',
  [MissionErrorCode.ORIGIN_COLONY_NOT_FOUND]: 'originColonyCode',
  [MissionErrorCode.ORIGIN_COLONY_INACTIVE]: 'originColonyCode',
};

/** `datetime-local` value read as UTC (BR-011), e.g. `2040-05-01T08:00` becomes `2040-05-01T08:00:00Z`. */
function toUtcInstant(local: string): string {
  return `${local}:00Z`;
}

/** The planned end must follow the planned start; reported as `window` on the group. */
const plannedWindow: ValidatorFn = (group: AbstractControl): ValidationErrors | null => {
  const start = group.get('plannedStartAt')?.value as string;
  const end = group.get('plannedEndAt')?.value as string;
  return start && end && end <= start ? { window: true } : null;
};

/** PHX-201: drafts a mission; the server assigns status DRAFT. */
@Component({
  selector: 'app-mission-form-page',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [NgTemplateOutlet, ReactiveFormsModule, RouterLink],
  templateUrl: './mission-form-page.html',
  styleUrls: ['../../../shared/styles/data-view.scss', '../../../shared/styles/form.scss'],
})
export class MissionFormPage {
  private readonly missions = inject(MissionService);
  private readonly router = inject(Router);
  private readonly route = inject(ActivatedRoute);
  private readonly destroyRef = inject(DestroyRef);

  protected readonly types = MISSION_TYPES;
  protected readonly typeLabels = MISSION_TYPE_LABELS;
  protected readonly priorities = MISSION_PRIORITIES;
  protected readonly priorityLabels = MISSION_PRIORITY_LABELS;
  protected readonly safetyLevels = SAFETY_LEVELS;
  protected readonly safetyLabels = SAFETY_LEVEL_LABELS;
  protected readonly colonies = signal<readonly Colony[]>([]);
  protected readonly submitting = signal(false);
  /** A failure that does not belong to a single field. */
  protected readonly formError = signal<ApiError | null>(null);

  protected readonly form = inject(NonNullableFormBuilder).group(
    {
      code: ['', [Validators.required, Validators.pattern(MISSION_CODE_PATTERN)]],
      title: ['', [Validators.required, Validators.maxLength(200)]],
      objective: ['', [Validators.required, Validators.maxLength(2000)]],
      description: ['', Validators.maxLength(4000)],
      type: ['' as MissionType | '', Validators.required],
      originColonyCode: ['', Validators.required],
      plannedStartAt: ['', Validators.required],
      plannedEndAt: ['', Validators.required],
      priority: ['MEDIUM' as MissionPriority, Validators.required],
      safetyLevel: ['STANDARD' as SafetyLevel, Validators.required],
    },
    { validators: plannedWindow },
  );

  constructor() {
    // Missions depart from active bases only.
    inject(ColonyService)
      .list(true, 0, MAX_PAGE_SIZE)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (page) => this.colonies.set(page.items),
        error: () => this.colonies.set([]),
      });
  }

  protected showErrors(name: FormField): boolean {
    const control = this.form.controls[name];
    const windowError = name === 'plannedEndAt' && this.form.hasError('window');
    return (control.invalid || windowError) && (control.touched || control.dirty);
  }

  /** First message for a field: the server's when present, otherwise the client validator's. */
  protected errorMessage(name: FormField): string {
    const errors = this.form.controls[name].errors ?? {};
    if (typeof errors['server'] === 'string') {
      return errors['server'];
    }
    if (errors['required']) {
      return 'This field is required.';
    }
    if (errors['pattern']) {
      return 'Use 3 to 60 letters, digits or dashes, starting with a letter or digit.';
    }
    if (errors['maxlength']) {
      return `Use at most ${(errors['maxlength'] as { requiredLength: number }).requiredLength} characters.`;
    }
    if (name === 'plannedEndAt' && this.form.hasError('window')) {
      return 'The end must be after the start.';
    }
    return 'Invalid value.';
  }

  protected submit(): void {
    this.formError.set(null);
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    const value = this.form.getRawValue();
    this.submitting.set(true);
    this.missions
      .create({
        ...value,
        type: value.type as MissionType,
        description: value.description.trim() || null,
        plannedStartAt: toUtcInstant(value.plannedStartAt),
        plannedEndAt: toUtcInstant(value.plannedEndAt),
      })
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (created) => {
          void this.router.navigate(['..'], {
            relativeTo: this.route,
            queryParams: { created: created.code },
          });
        },
        error: (error: unknown) => {
          this.submitting.set(false);
          this.applyServerError(toApiError(error));
        },
      });
  }

  private applyServerError(error: ApiError): void {
    const field = FIELD_OF_CODE[error.code];
    if (field) {
      this.setServerError(field, error.message);
      return;
    }
    let mapped = false;
    for (const violation of error.fieldErrors) {
      if (violation.field in this.form.controls) {
        this.setServerError(violation.field as FormField, `This value ${violation.message}.`);
        mapped = true;
      }
    }
    if (!mapped) {
      this.formError.set(error);
    }
  }

  private setServerError(field: FormField, message: string): void {
    const control = this.form.controls[field];
    control.setErrors({ ...control.errors, server: message });
    control.markAsTouched();
  }
}
