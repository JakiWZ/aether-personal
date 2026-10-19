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
import {
  CRITICALITY_LABELS,
  VEHICLE_STATUSES,
  VEHICLE_STATUS_LABELS,
  Vehicle,
  VehicleService,
  VehicleStatus,
} from '../data/vehicle.service';

/** Which vehicles to show: every status, or one of them. */
export type StatusFilter = 'all' | VehicleStatus;

type ViewState =
  | { readonly kind: 'loading' }
  | { readonly kind: 'loaded'; readonly page: Page<Vehicle> }
  | { readonly kind: 'error'; readonly error: ApiError };

/** TIT-301: fleet catalogue with type, status, criticality and base; retired vehicles stay listed. */
@Component({
  selector: 'app-vehicle-list-page',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [Pager],
  templateUrl: './vehicle-list-page.html',
  styleUrls: ['../../../shared/styles/data-view.scss', './vehicle-list-page.scss'],
})
export class VehicleListPage {
  private readonly vehicles = inject(VehicleService);
  private readonly destroyRef = inject(DestroyRef);
  private request?: Subscription;

  protected readonly statuses = VEHICLE_STATUSES;
  protected readonly statusLabels = VEHICLE_STATUS_LABELS;
  protected readonly criticalityLabels = CRITICALITY_LABELS;
  protected readonly filter = signal<StatusFilter>('all');
  protected readonly state = signal<ViewState>({ kind: 'loading' });
  protected readonly filterLabel = computed(() => {
    const filter = this.filter();
    return filter === 'all' ? null : VEHICLE_STATUS_LABELS[filter];
  });

  protected readonly vehiclePage = computed(() => {
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
    this.filter.set((event.target as HTMLSelectElement).value as StatusFilter);
    this.load(0);
  }

  protected load(page = this.pageIndex): void {
    this.pageIndex = page;
    this.request?.unsubscribe();
    this.state.set({ kind: 'loading' });
    const filter = this.filter();
    this.request = this.vehicles
      .list(filter === 'all' ? undefined : filter, page, DEFAULT_PAGE_SIZE)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (result) => this.state.set({ kind: 'loaded', page: result }),
        error: (error: unknown) => this.state.set({ kind: 'error', error: toApiError(error) }),
      });
  }
}
