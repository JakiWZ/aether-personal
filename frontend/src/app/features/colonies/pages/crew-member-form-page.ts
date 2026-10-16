import { ChangeDetectionStrategy, Component, DestroyRef, inject, signal } from '@angular/core';
import { NgTemplateOutlet } from '@angular/common';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import {
  AbstractControl,
  NonNullableFormBuilder,
  ReactiveFormsModule,
  Validators,
} from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';

import { ApiError, toApiError } from '../../../core/http/api-error';
import { Colony, ColonyService } from '../data/colony.service';
import {
  CREW_STATUSES,
  CREW_STATUS_LABELS,
  CrewErrorCode,
  CrewMemberService,
  CrewStatus,
} from '../data/crew-member.service';

/** Mirrors the backend pattern; the server stays authoritative. */
const EMPLOYEE_CODE_PATTERN = /^[A-Za-z0-9][A-Za-z0-9-]{2,39}$/;

/** Backend codes that belong to one field rather than to the whole form. */
const FIELD_OF_CODE: Partial<Record<string, FormField>> = {
  [CrewErrorCode.CREW_MEMBER_CODE_TAKEN]: 'employeeCode',
  [CrewErrorCode.PERSON_EMAIL_TAKEN]: 'email',
  [CrewErrorCode.HOME_COLONY_NOT_FOUND]: 'homeColonyCode',
  [CrewErrorCode.HOME_COLONY_INACTIVE]: 'homeColonyCode',
};

type FormField =
  | 'employeeCode'
  | 'firstName'
  | 'lastName'
  | 'email'
  | 'operationalRole'
  | 'status'
  | 'homeColonyCode';

/** ARES-103: registers a crew member. */
@Component({
  selector: 'app-crew-member-form-page',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [NgTemplateOutlet, ReactiveFormsModule, RouterLink],
  templateUrl: './crew-member-form-page.html',
  styleUrls: ['../../../shared/styles/data-view.scss', '../../../shared/styles/form.scss'],
})
export class CrewMemberFormPage {
  private readonly crew = inject(CrewMemberService);
  private readonly router = inject(Router);
  private readonly route = inject(ActivatedRoute);
  private readonly destroyRef = inject(DestroyRef);

  protected readonly statuses = CREW_STATUSES;
  protected readonly statusLabels = CREW_STATUS_LABELS;
  protected readonly colonies = signal<readonly Colony[]>([]);
  protected readonly submitting = signal(false);
  /** A failure that does not belong to a single field. */
  protected readonly formError = signal<ApiError | null>(null);

  protected readonly form = inject(NonNullableFormBuilder).group({
    employeeCode: ['', [Validators.required, Validators.pattern(EMPLOYEE_CODE_PATTERN)]],
    firstName: ['', [Validators.required, Validators.maxLength(100)]],
    lastName: ['', [Validators.required, Validators.maxLength(100)]],
    email: ['', [Validators.email, Validators.maxLength(200)]],
    operationalRole: ['', [Validators.required, Validators.maxLength(80)]],
    status: ['ACTIVE' as CrewStatus, Validators.required],
    homeColonyCode: [''],
  });

  constructor() {
    // Only active bases can receive crew members; without the list the field stays optional.
    inject(ColonyService)
      .list(true)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({ next: (list) => this.colonies.set(list), error: () => this.colonies.set([]) });
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
    if (errors['pattern']) {
      return 'Use 3 to 40 letters, digits or dashes, starting with a letter or digit.';
    }
    if (errors['email']) {
      return 'Enter a valid email address.';
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
    this.crew
      .create({
        ...value,
        email: value.email.trim() || null,
        homeColonyCode: value.homeColonyCode || null,
      })
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (created) => {
          void this.router.navigate(['..'], {
            relativeTo: this.route,
            queryParams: { created: created.employeeCode },
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
