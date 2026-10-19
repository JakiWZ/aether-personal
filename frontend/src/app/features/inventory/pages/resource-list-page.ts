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
import { Subscription } from 'rxjs';

import { AuthService } from '../../../core/auth/auth.service';
import { ApiError, toApiError } from '../../../core/http/api-error';
import { DEFAULT_PAGE_SIZE, Page } from '../../../core/http/page';
import { Pager } from '../../../shared/ui/pager/pager';
import { RESOURCE_CATEGORY_LABELS, Resource, ResourceService } from '../data/resource.service';

/** Which resources to show; maps to the `active` query parameter. */
export type ActivityFilter = 'all' | 'active' | 'inactive';

type ViewState =
  | { readonly kind: 'loading' }
  | { readonly kind: 'loaded'; readonly page: Page<Resource> }
  | { readonly kind: 'error'; readonly error: ApiError };

/** Outcome of the last activation or deactivation, announced above the table. */
type ActivityChange =
  | { readonly kind: 'done'; readonly code: string; readonly active: boolean }
  | { readonly kind: 'failed'; readonly code: string; readonly error: ApiError };

const FILTER_PARAM: Record<ActivityFilter, boolean | undefined> = {
  all: undefined,
  active: true,
  inactive: false,
};

/** ORI-401: resource catalogue; inactive resources stay listed and can be reactivated. */
@Component({
  selector: 'app-resource-list-page',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [Pager, RouterLink],
  templateUrl: './resource-list-page.html',
  styleUrls: ['../../../shared/styles/data-view.scss', './resource-list-page.scss'],
})
export class ResourceListPage {
  private readonly resources = inject(ResourceService);
  private readonly destroyRef = inject(DestroyRef);
  private readonly auth = inject(AuthService);
  private request?: Subscription;

  /** Code of a resource just created, from the `created` query parameter. */
  readonly created = input<string>();

  /** Only offered to who may do it; the server refuses the others anyway. */
  protected readonly canManage = computed(() => this.auth.hasPermission('INVENTORY_MANAGE'));
  protected readonly categoryLabels = RESOURCE_CATEGORY_LABELS;
  protected readonly filter = signal<ActivityFilter>('all');
  protected readonly state = signal<ViewState>({ kind: 'loading' });
  /** Code of the resource whose activity is being changed. */
  protected readonly pending = signal<string | null>(null);
  protected readonly change = signal<ActivityChange | null>(null);

  protected readonly resourcePage = computed(() => {
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
    this.change.set(null);
    this.load(0);
  }

  protected toggle(resource: Resource): void {
    const active = !resource.active;
    this.pending.set(resource.code);
    this.change.set(null);
    this.resources
      .setActive(resource.code, active)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: () => {
          this.pending.set(null);
          this.change.set({ kind: 'done', code: resource.code, active });
          this.load();
        },
        error: (error: unknown) => {
          this.pending.set(null);
          this.change.set({ kind: 'failed', code: resource.code, error: toApiError(error) });
        },
      });
  }

  protected load(page = this.pageIndex): void {
    this.pageIndex = page;
    this.request?.unsubscribe();
    this.state.set({ kind: 'loading' });
    this.request = this.resources
      .list(FILTER_PARAM[this.filter()], page, DEFAULT_PAGE_SIZE)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (result) => this.state.set({ kind: 'loaded', page: result }),
        error: (error: unknown) => this.state.set({ kind: 'error', error: toApiError(error) }),
      });
  }
}
