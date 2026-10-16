import { Routes } from '@angular/router';

import { authGuard } from './core/auth/auth.guard';
import { domainByPath } from './core/navigation/domains';
import { NotFoundPage } from './features/not-found/not-found-page';

/**
 * One lazy-loaded route per business domain, mirroring the backend packages. Every domain needs a
 * session (ADR-0012); the login page is the only one open to everybody.
 */
export const routes: Routes = [
  { path: '', pathMatch: 'full', redirectTo: 'dashboard' },
  {
    path: 'login',
    title: 'Sign in',
    loadComponent: () => import('./features/login/login-page').then((m) => m.LoginPage),
  },
  {
    path: 'dashboard',
    title: 'Mission Control',
    canMatch: [authGuard],
    loadChildren: () =>
      import('./features/dashboard/dashboard.routes').then((m) => m.DASHBOARD_ROUTES),
  },
  {
    path: 'colonies',
    title: domainByPath('colonies').label,
    canMatch: [authGuard],
    loadChildren: () =>
      import('./features/colonies/colonies.routes').then((m) => m.COLONIES_ROUTES),
  },
  {
    path: 'missions',
    title: domainByPath('missions').label,
    canMatch: [authGuard],
    loadChildren: () =>
      import('./features/missions/missions.routes').then((m) => m.MISSIONS_ROUTES),
  },
  {
    path: 'fleet',
    title: domainByPath('fleet').label,
    canMatch: [authGuard],
    loadChildren: () => import('./features/fleet/fleet.routes').then((m) => m.FLEET_ROUTES),
  },
  {
    path: 'inventory',
    title: domainByPath('inventory').label,
    canMatch: [authGuard],
    loadChildren: () =>
      import('./features/inventory/inventory.routes').then((m) => m.INVENTORY_ROUTES),
  },
  {
    path: 'incidents',
    title: domainByPath('incidents').label,
    canMatch: [authGuard],
    loadChildren: () =>
      import('./features/incidents/incidents.routes').then((m) => m.INCIDENTS_ROUTES),
  },
  { path: '**', title: 'Page not found', component: NotFoundPage },
];
