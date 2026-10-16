import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';

import { DOMAINS } from '../../core/navigation/domains';
import { BackendStatus } from '../backend-status/backend-status';

/** Application frame: skip link, header with navigation, routed content. */
@Component({
  selector: 'app-shell',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterOutlet, RouterLink, RouterLinkActive, BackendStatus],
  templateUrl: './shell.html',
  styleUrl: './shell.scss',
})
export class Shell {
  protected readonly domains = DOMAINS;
}
