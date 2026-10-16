import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterLink } from '@angular/router';

import { DOMAINS } from '../../core/navigation/domains';

/** Mission Control entry point. Will aggregate live data from every domain (Sprint 3). */
@Component({
  selector: 'app-dashboard-page',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink],
  template: `
    <h1>Mission Control</h1>
    <p>Panoramica operativa delle colonie marziane.</p>
    <ul class="domains">
      @for (d of domains; track d.path) {
        <li>
          <a [routerLink]="['/', d.path]">
            <span class="label">{{ d.label }}</span>
            <span class="squad">{{ d.squad }}</span>
          </a>
          <p>{{ d.summary }}</p>
        </li>
      }
    </ul>
  `,
  styles: `
    .domains {
      display: grid;
      gap: 1rem;
      grid-template-columns: repeat(auto-fill, minmax(16rem, 1fr));
      list-style: none;
      padding: 0;
    }
    li {
      background: var(--aether-surface);
      border: 1px solid var(--aether-border);
      border-radius: 0.5rem;
      padding: 1rem;
    }
    a {
      display: flex;
      justify-content: space-between;
      font-weight: 600;
    }
    .squad {
      color: var(--aether-text-muted);
      font-size: 0.85rem;
    }
  `,
})
export class DashboardPage {
  protected readonly domains = DOMAINS;
}
