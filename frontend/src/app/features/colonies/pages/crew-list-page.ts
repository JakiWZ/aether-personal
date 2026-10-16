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

import { ApiError, toApiError } from '../../../core/http/api-error';
import { CREW_STATUS_LABELS, CrewMember, CrewMemberService } from '../data/crew-member.service';

type ViewState =
  | { readonly kind: 'loading' }
  | { readonly kind: 'loaded'; readonly members: readonly CrewMember[] }
  | { readonly kind: 'error'; readonly error: ApiError };

/** ARES-103: crew registry, read back from the server after every registration. */
@Component({
  selector: 'app-crew-list-page',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink],
  templateUrl: './crew-list-page.html',
  styleUrls: ['../../../shared/styles/data-view.scss'],
})
export class CrewListPage {
  private readonly crew = inject(CrewMemberService);
  private readonly destroyRef = inject(DestroyRef);

  /** Employee code of a member just registered, from the `created` query parameter. */
  readonly created = input<string>();

  protected readonly state = signal<ViewState>({ kind: 'loading' });
  protected readonly statusLabels = CREW_STATUS_LABELS;

  protected readonly members = computed(() => {
    const state = this.state();
    return state.kind === 'loaded' ? state.members : null;
  });
  protected readonly error = computed(() => {
    const state = this.state();
    return state.kind === 'error' ? state.error : null;
  });

  constructor() {
    this.load();
  }

  protected load(): void {
    this.state.set({ kind: 'loading' });
    this.crew
      .list()
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (members) => this.state.set({ kind: 'loaded', members }),
        error: (error: unknown) => this.state.set({ kind: 'error', error: toApiError(error) }),
      });
  }
}
