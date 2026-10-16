import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';

import { DOMAINS } from '../../../core/navigation/domains';

/**
 * Landing page of a domain whose screens are not built yet. Bound to the route's `domain` data
 * through router input binding, so each feature only declares which domain it is.
 */
@Component({
  selector: 'app-feature-placeholder',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    @if (info(); as d) {
      <h1>{{ d.label }}</h1>
      <p class="squad">Squad {{ d.squad }}</p>
      <p>{{ d.summary }}</p>
      <p class="note">Le funzionalità di questa area saranno disponibili nei prossimi sprint.</p>
    }
  `,
  styles: `
    .squad {
      color: var(--aether-text-muted);
      font-weight: 600;
      letter-spacing: 0.05em;
    }
    .note {
      border-left: 4px solid var(--aether-accent);
      padding-left: 0.75rem;
    }
  `,
})
export class FeaturePlaceholder {
  /** Path of the domain in {@link DOMAINS}. */
  readonly domain = input.required<string>();

  protected readonly info = computed(() => DOMAINS.find((d) => d.path === this.domain()));
}
