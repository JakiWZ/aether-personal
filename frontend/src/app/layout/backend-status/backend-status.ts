import { ChangeDetectionStrategy, Component, DestroyRef, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';

import { BackendHealth, BackendHealthService } from '../../core/health/backend-health.service';

type StatusState = 'loading' | BackendHealth;

const LABELS: Record<StatusState, string> = {
  loading: 'Verifica backend…',
  up: 'Backend operativo',
  down: 'Backend non operativo',
  unreachable: 'Backend non raggiungibile',
};

/** Small indicator of backend availability, shown in the header. */
@Component({
  selector: 'app-backend-status',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <span class="status" [attr.data-state]="state()" role="status">
      <span class="dot" aria-hidden="true"></span>{{ label() }}
    </span>
    @if (state() === 'down' || state() === 'unreachable') {
      <button type="button" (click)="refresh()">Riprova</button>
    }
  `,
  styles: `
    :host {
      display: inline-flex;
      align-items: center;
      gap: 0.5rem;
      font-size: 0.875rem;
    }
    .dot {
      display: inline-block;
      width: 0.6rem;
      height: 0.6rem;
      margin-right: 0.4rem;
      border-radius: 50%;
      background: var(--aether-text-muted);
    }
    [data-state='up'] .dot {
      background: var(--aether-ok);
    }
    [data-state='down'] .dot,
    [data-state='unreachable'] .dot {
      background: var(--aether-danger);
    }
  `,
})
export class BackendStatus {
  private readonly health = inject(BackendHealthService);
  private readonly destroyRef = inject(DestroyRef);

  protected readonly state = signal<StatusState>('loading');
  protected readonly label = () => LABELS[this.state()];

  constructor() {
    this.refresh();
  }

  refresh(): void {
    this.state.set('loading');
    this.health
      .check()
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe((result) => this.state.set(result));
  }
}
