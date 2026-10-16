import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterLink } from '@angular/router';

@Component({
  selector: 'app-not-found-page',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink],
  template: `
    <h1>Pagina non trovata</h1>
    <p>L’indirizzo richiesto non esiste.</p>
    <a routerLink="/dashboard">Torna a Mission Control</a>
  `,
})
export class NotFoundPage {}
