import { DatePipe } from '@angular/common';
import {
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  computed,
  inject,
  input,
  signal,
} from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { RouterLink } from '@angular/router';

import { AuthService } from '../../../core/auth/auth.service';
import { ApiError, toApiError } from '../../../core/http/api-error';
import { Page } from '../../../core/http/page';
import { Pager } from '../../../shared/ui/pager/pager';
import {
  INCIDENT_SEVERITY_LABELS,
  INCIDENT_STATUS_LABELS,
  Incident,
  IncidentService,
} from '../data/incident.service';

type ViewState =
  | { readonly kind: 'loading' }
  | { readonly kind: 'loaded'; readonly page: Page<Incident> }
  | { readonly kind: 'error'; readonly error: ApiError };

/** HEL-501: incidents newest first, read back from the server after every report. */
@Component({
  selector: 'app-incident-list-page',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [DatePipe, Pager, RouterLink],
  templateUrl: './incident-list-page.html',
  styleUrls: ['../../../shared/styles/data-view.scss', './incident-list-page.scss'],
})
export class IncidentListPage {
  private readonly service = inject(IncidentService);
  private readonly destroyRef = inject(DestroyRef);
  private readonly auth = inject(AuthService);

  /** Code of an incident just opened, from the `created` query parameter. */
  readonly created = input<string>();

  /** Only offered to who may do it; the server refuses the others anyway. */
  protected readonly canReport = computed(() => this.auth.hasPermission('INCIDENT_REPORT'));
  protected readonly state = signal<ViewState>({ kind: 'loading' });
  protected readonly severityLabels = INCIDENT_SEVERITY_LABELS;
  protected readonly statusLabels = INCIDENT_STATUS_LABELS;

  protected readonly incidentPage = computed(() => {
    const state = this.state();
    return state.kind === 'loaded' ? state.page : null;
  });
  private pageIndex = 0;
  protected readonly error = computed(() => {
    const state = this.state();
    return state.kind === 'error' ? state.error : null;
  });

  constructor() {
    this.load();
  }

  protected load(page = this.pageIndex): void {
    this.pageIndex = page;
    this.state.set({ kind: 'loading' });
    this.service
      .list(page)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (result) => this.state.set({ kind: 'loaded', page: result }),
        error: (error: unknown) => this.state.set({ kind: 'error', error: toApiError(error) }),
      });
  }
}
