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
  MISSION_PRIORITY_LABELS,
  MISSION_STATUS_LABELS,
  MISSION_TYPE_LABELS,
  Mission,
  MissionService,
  SAFETY_LEVEL_LABELS,
} from '../data/mission.service';

type ViewState =
  | { readonly kind: 'loading' }
  | { readonly kind: 'loaded'; readonly page: Page<Mission> }
  | { readonly kind: 'error'; readonly error: ApiError };

/** PHX-201: missions with their planned window, read back from the server after every creation. */
@Component({
  selector: 'app-mission-list-page',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [DatePipe, Pager, RouterLink],
  templateUrl: './mission-list-page.html',
  styleUrls: ['../../../shared/styles/data-view.scss', './mission-list-page.scss'],
})
export class MissionListPage {
  private readonly service = inject(MissionService);
  private readonly destroyRef = inject(DestroyRef);
  private readonly auth = inject(AuthService);

  /** Code of a mission just drafted, from the `created` query parameter. */
  readonly created = input<string>();

  /** Only offered to who may do it; the server refuses the others anyway. */
  protected readonly canCreate = computed(() => this.auth.hasPermission('MISSION_MANAGE'));
  protected readonly state = signal<ViewState>({ kind: 'loading' });
  protected readonly statusLabels = MISSION_STATUS_LABELS;
  protected readonly typeLabels = MISSION_TYPE_LABELS;
  protected readonly priorityLabels = MISSION_PRIORITY_LABELS;
  protected readonly safetyLabels = SAFETY_LEVEL_LABELS;

  protected readonly missionPage = computed(() => {
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
