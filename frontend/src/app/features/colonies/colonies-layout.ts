import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';

/** Frame of the Colonies & Crew area: local navigation between its screens. */
@Component({
  selector: 'app-colonies-layout',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, RouterLinkActive, RouterOutlet],
  template: `
    <nav aria-label="Colonies and crew">
      <a
        routerLink="."
        routerLinkActive="active"
        [routerLinkActiveOptions]="{ exact: true }"
        ariaCurrentWhenActive="page"
        >Bases</a
      >
      <a routerLink="crew" routerLinkActive="active" ariaCurrentWhenActive="page">Crew</a>
    </nav>
    <router-outlet />
  `,
  styles: `
    nav {
      display: flex;
      gap: 1rem;
      border-bottom: 1px solid var(--aether-border);
      margin-bottom: 1rem;
    }
    a {
      padding: 0.5rem 0;
      text-decoration: none;
      font-weight: 600;
      border-bottom: 3px solid transparent;
    }
    a.active {
      border-bottom-color: var(--aether-accent);
    }
  `,
})
export class ColoniesLayout {}
