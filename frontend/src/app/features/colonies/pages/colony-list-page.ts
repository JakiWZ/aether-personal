import {
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  computed,
  inject,
  signal,
} from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { Subscription } from 'rxjs';

import { ApiError, toApiError } from '../../../core/http/api-error';
import { Colony, ColonyService, ColonyStatus } from '../data/colony.service';

/** Which bases to show; maps to the `active` query parameter. */
export type ActivityFilter = 'all' | 'active' | 'inactive';

type ViewState =
  | { readonly kind: 'loading' }
  | { readonly kind: 'loaded'; readonly colonies: readonly Colony[] }
  | { readonly kind: 'error'; readonly error: ApiError };

const FILTER_PARAM: Record<ActivityFilter, boolean | undefined> = {
  all: undefined,
  active: true,
  inactive: false,
};

const STATUS_LABELS: Record<ColonyStatus, string> = {
  PLANNED: 'Planned',
  CONSTRUCTION: 'Under construction',
  OPERATIONAL: 'Operational',
  DEGRADED: 'Degraded',
  EMERGENCY: 'Emergency',
  INACTIVE: 'Inactive',
};

/** ARES-101: list of the Martian bases with code, name and operational status. */
@Component({
  selector: 'app-colony-list-page',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './colony-list-page.html',
  styleUrls: ['../shared/data-view.scss', './colony-list-page.scss'],
})
export class ColonyListPage {
  private readonly colonies = inject(ColonyService);
  private readonly destroyRef = inject(DestroyRef);
  private request?: Subscription;

  protected readonly filter = signal<ActivityFilter>('all');
  protected readonly state = signal<ViewState>({ kind: 'loading' });
  protected readonly statusLabels = STATUS_LABELS;

  protected readonly loadedColonies = computed(() => {
    const state = this.state();
    return state.kind === 'loaded' ? state.colonies : null;
  });
  protected readonly error = computed(() => {
    const state = this.state();
    return state.kind === 'error' ? state.error : null;
  });

  constructor() {
    this.load();
  }

  protected onFilterChange(event: Event): void {
    this.filter.set((event.target as HTMLSelectElement).value as ActivityFilter);
    this.load();
  }

  protected load(): void {
    this.request?.unsubscribe();
    this.state.set({ kind: 'loading' });
    this.request = this.colonies
      .list(FILTER_PARAM[this.filter()])
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (colonies) => this.state.set({ kind: 'loaded', colonies }),
        error: (error: unknown) => this.state.set({ kind: 'error', error: toApiError(error) }),
      });
  }
}
