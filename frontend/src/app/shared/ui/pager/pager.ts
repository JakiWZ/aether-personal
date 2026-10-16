import { ChangeDetectionStrategy, Component, computed, input, output } from '@angular/core';

import { Page } from '../../../core/http/page';

/**
 * Previous / next navigation for a server-side page (ADR-0011). Shows where the user is and how
 * many items exist; the buttons only appear when there is more than one page.
 */
@Component({
  selector: 'app-pager',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './pager.html',
  styleUrl: './pager.scss',
})
export class Pager {
  readonly page = input.required<Page<unknown>>();
  /** What one item is, for the summary ("1 mission"). */
  readonly singular = input.required<string>();
  /** What several items are ("12 missions"). */
  readonly plural = input.required<string>();

  /** Emits the zero-based index of the page to load. */
  readonly pageChange = output<number>();

  protected readonly noun = computed(() =>
    this.page().totalItems === 1 ? this.singular() : this.plural(),
  );
  protected readonly hasPrevious = computed(() => this.page().page > 0);
  protected readonly hasNext = computed(() => this.page().page + 1 < this.page().totalPages);

  protected previous(): void {
    this.pageChange.emit(this.page().page - 1);
  }

  protected next(): void {
    this.pageChange.emit(this.page().page + 1);
  }
}
