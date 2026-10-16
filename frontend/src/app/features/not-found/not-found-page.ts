import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterLink } from '@angular/router';

@Component({
  selector: 'app-not-found-page',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink],
  template: `
    <h1>Page not found</h1>
    <p>The requested address does not exist.</p>
    <a routerLink="/dashboard">Back to Mission Control</a>
  `,
})
export class NotFoundPage {}
