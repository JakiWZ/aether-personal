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
import { CREW_STATUS_LABELS, CrewMember, CrewMemberService } from '../data/crew-member.service';

type ViewState =
  | { readonly kind: 'loading' }
  | { readonly kind: 'loaded'; readonly page: Page<CrewMember> }
  | { readonly kind: 'error'; readonly error: ApiError };

/** ARES-103: crew registry, read back from the server after every registration. */
@Component({
  selector: 'app-crew-list-page',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [Pager, RouterLink],
  templateUrl: './crew-list-page.html',
  styleUrls: ['../../../shared/styles/data-view.scss'],
})
export class CrewListPage {
  private readonly crew = inject(CrewMemberService);
  private readonly destroyRef = inject(DestroyRef);
  private readonly auth = inject(AuthService);

  /** Employee code of a member just registered, from the `created` query parameter. */
  readonly created = input<string>();

  /** Only offered to who may do it; the server refuses the others anyway. */
  protected readonly canCreate = computed(() => this.auth.hasPermission('CREW_MANAGE'));
  protected readonly state = signal<ViewState>({ kind: 'loading' });
  protected readonly statusLabels = CREW_STATUS_LABELS;

  protected readonly memberPage = computed(() => {
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
    this.crew
      .list(page)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (result) => this.state.set({ kind: 'loaded', page: result }),
        error: (error: unknown) => this.state.set({ kind: 'error', error: toApiError(error) }),
      });
  }
}
