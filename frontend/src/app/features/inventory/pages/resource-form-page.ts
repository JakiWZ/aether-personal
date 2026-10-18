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
import {
  InventoryErrorCode,
  RESOURCE_CATEGORIES,
  RESOURCE_CATEGORY_LABELS,
  ResourceCategory,
  ResourceService,
  UnitOfMeasure,
} from '../data/resource.service';

/** Mirrors the backend pattern; the server stays authoritative. */
const RESOURCE_CODE_PATTERN = /^[A-Za-z0-9][A-Za-z0-9_-]{1,49}$/;

/** Backend codes that belong to one field rather than to the whole form. */
const FIELD_OF_CODE: Partial<Record<string, FormField>> = {
  [InventoryErrorCode.RESOURCE_CODE_TAKEN]: 'code',
  [InventoryErrorCode.UNIT_OF_MEASURE_NOT_FOUND]: 'unitCode',
};

type FormField = 'code' | 'name' | 'category' | 'unitCode' | 'critical' | 'shelfLifeDays';

/** ORI-401: adds a resource to the catalogue. The unit is always chosen, never guessed. */
@Component({
  selector: 'app-resource-form-page',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [NgTemplateOutlet, ReactiveFormsModule, RouterLink],
  templateUrl: './resource-form-page.html',
  styleUrls: ['../../../shared/styles/data-view.scss', '../../../shared/styles/form.scss'],
})
export class ResourceFormPage {
  private readonly resources = inject(ResourceService);
  private readonly router = inject(Router);
  private readonly route = inject(ActivatedRoute);
  private readonly destroyRef = inject(DestroyRef);

  protected readonly categories = RESOURCE_CATEGORIES;
  protected readonly categoryLabels = RESOURCE_CATEGORY_LABELS;
  protected readonly units = signal<readonly UnitOfMeasure[]>([]);
  protected readonly unitsError = signal(false);
  protected readonly submitting = signal(false);
  /** A failure that does not belong to a single field. */
  protected readonly formError = signal<ApiError | null>(null);

  protected readonly form = inject(NonNullableFormBuilder).group({
    code: ['', [Validators.required, Validators.pattern(RESOURCE_CODE_PATTERN)]],
    name: ['', [Validators.required, Validators.maxLength(150)]],
    category: ['' as ResourceCategory | '', Validators.required],
    unitCode: ['', Validators.required],
    critical: [false],
    shelfLifeDays: [null as number | null, [Validators.min(1), Validators.max(36500)]],
  });

  constructor() {
    this.resources
      .units()
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (page) => this.units.set(page.items),
        error: () => this.unitsError.set(true),
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
    if (errors['pattern']) {
      return 'Use 2 to 50 letters, digits, dashes or underscores, starting with a letter or digit.';
    }
    if (errors['maxlength']) {
      return `Use at most ${(errors['maxlength'] as { requiredLength: number }).requiredLength} characters.`;
    }
    if (errors['min'] || errors['max']) {
      return 'Enter a number of days between 1 and 36500.';
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
    this.resources
      .create({
        code: value.code,
        name: value.name,
        category: value.category as ResourceCategory,
        unitCode: value.unitCode,
        critical: value.critical,
        shelfLifeDays: value.shelfLifeDays ?? null,
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
    const control = this.control(field);
    control.setErrors({ ...control.errors, server: message });
    control.markAsTouched();
  }
}
