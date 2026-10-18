import { NgTemplateOutlet } from '@angular/common';
import { ChangeDetectionStrategy, Component, DestroyRef, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import {
  AbstractControl,
  NonNullableFormBuilder,
  ReactiveFormsModule,
  Validators,
} from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';

import { ApiError, toApiError } from '../../../core/http/api-error';
import { MAX_PAGE_SIZE } from '../../../core/http/page';
import { Colony, ColonyService } from '../../colonies/data/colony.service';
import {
  INCIDENT_SEVERITIES,
  INCIDENT_SEVERITY_HINTS,
  INCIDENT_SEVERITY_LABELS,
  IncidentErrorCode,
  IncidentService,
  IncidentSeverity,
} from '../data/incident.service';

/** Backend codes that belong to one field rather than to the whole form. */
const FIELD_OF_CODE: Partial<Record<string, FormField>> = {
  [IncidentErrorCode.INCIDENT_COLONY_NOT_FOUND]: 'colonyCode',
};

type FormField = 'colonyCode' | 'title' | 'description' | 'severity';

/** HEL-501: reports an incident. Code, status OPEN and opening time come from the server. */
@Component({
  selector: 'app-incident-form-page',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [NgTemplateOutlet, ReactiveFormsModule, RouterLink],
  templateUrl: './incident-form-page.html',
  styleUrls: ['../../../shared/styles/data-view.scss', '../../../shared/styles/form.scss'],
})
export class IncidentFormPage {
  private readonly incidents = inject(IncidentService);
  private readonly router = inject(Router);
  private readonly route = inject(ActivatedRoute);
  private readonly destroyRef = inject(DestroyRef);

  protected readonly severities = INCIDENT_SEVERITIES;
  protected readonly severityLabels = INCIDENT_SEVERITY_LABELS;
  protected readonly severityHints = INCIDENT_SEVERITY_HINTS;
  protected readonly colonies = signal<readonly Colony[]>([]);
  protected readonly coloniesError = signal(false);
  protected readonly submitting = signal(false);
  /** A failure that does not belong to a single field. */
  protected readonly formError = signal<ApiError | null>(null);

  protected readonly form = inject(NonNullableFormBuilder).group({
    colonyCode: ['', Validators.required],
    title: ['', [Validators.required, Validators.maxLength(200)]],
    description: ['', [Validators.required, Validators.maxLength(4000)]],
    severity: ['' as IncidentSeverity | '', Validators.required],
  });

  constructor() {
    // Incidents can happen on inactive bases too, so every base is offered.
    inject(ColonyService)
      .list(undefined, 0, MAX_PAGE_SIZE)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (page) => this.colonies.set(page.items),
        error: () => this.coloniesError.set(true),
      });
  }

  protected control(name: FormField): AbstractControl {
    return this.form.controls[name];
  }

  protected showErrors(name: FormField): boolean {
    const control = this.control(name);
    return control.invalid && (control.touched || control.dirty);
  }

  /** First message for a field: the server's when present, otherwise the client validator's. */
  protected errorMessage(name: FormField): string {
    const errors = this.control(name).errors ?? {};
    if (typeof errors['server'] === 'string') {
      return errors['server'];
    }
    if (errors['required']) {
      return 'This field is required.';
    }
    if (errors['maxlength']) {
      return `Use at most ${(errors['maxlength'] as { requiredLength: number }).requiredLength} characters.`;
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
    this.incidents
      .open({ ...value, severity: value.severity as IncidentSeverity })
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (opened) => {
          void this.router.navigate(['..'], {
            relativeTo: this.route,
            queryParams: { created: opened.code },
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
    const control = this.control(field);
    control.setErrors({ ...control.errors, server: message });
    control.markAsTouched();
  }
}
