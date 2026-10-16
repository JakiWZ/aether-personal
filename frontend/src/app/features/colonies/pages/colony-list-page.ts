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
import { DEFAULT_PAGE_SIZE, Page } from '../../../core/http/page';
import { Pager } from '../../../shared/ui/pager/pager';
import { Colony, ColonyService, ColonyStatus } from '../data/colony.service';

/** Which bases to show; maps to the `active` query parameter. */
export type ActivityFilter = 'all' | 'active' | 'inactive';

type ViewState =
  | { readonly kind: 'loading' }
  | { readonly kind: 'loaded'; readonly page: Page<Colony> }
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
  imports: [Pager],
  templateUrl: './colony-list-page.html',
  styleUrls: ['../../../shared/styles/data-view.scss', './colony-list-page.scss'],
})
export class ColonyListPage {
  private readonly colonies = inject(ColonyService);
  private readonly destroyRef = inject(DestroyRef);
  private request?: Subscription;

  protected readonly filter = signal<ActivityFilter>('all');
  protected readonly state = signal<ViewState>({ kind: 'loading' });
  protected readonly statusLabels = STATUS_LABELS;

  protected readonly colonyPage = computed(() => {
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

  protected onFilterChange(event: Event): void {
    this.filter.set((event.target as HTMLSelectElement).value as ActivityFilter);
    this.load(0);
  }

  protected load(page = this.pageIndex): void {
    this.pageIndex = page;
    this.request?.unsubscribe();
    this.state.set({ kind: 'loading' });
    this.request = this.colonies
      .list(FILTER_PARAM[this.filter()], page, DEFAULT_PAGE_SIZE)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (result) => this.state.set({ kind: 'loaded', page: result }),
        error: (error: unknown) => this.state.set({ kind: 'error', error: toApiError(error) }),
      });
  }
}
