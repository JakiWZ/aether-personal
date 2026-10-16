import { Routes } from '@angular/router';

import { domainByPath } from './core/navigation/domains';
import { NotFoundPage } from './features/not-found/not-found-page';

/** One lazy-loaded route per business domain, mirroring the backend packages. */
export const routes: Routes = [
  { path: '', pathMatch: 'full', redirectTo: 'dashboard' },
  {
    path: 'dashboard',
    title: 'Mission Control',
    loadChildren: () =>
      import('./features/dashboard/dashboard.routes').then((m) => m.DASHBOARD_ROUTES),
  },
  {
    path: 'colonies',
    title: domainByPath('colonies').label,
    loadChildren: () =>
      import('./features/colonies/colonies.routes').then((m) => m.COLONIES_ROUTES),
  },
  {
    path: 'missions',
    title: domainByPath('missions').label,
    loadChildren: () =>
      import('./features/missions/missions.routes').then((m) => m.MISSIONS_ROUTES),
  },
  {
    path: 'fleet',
    title: domainByPath('fleet').label,
    loadChildren: () => import('./features/fleet/fleet.routes').then((m) => m.FLEET_ROUTES),
  },
  {
    path: 'inventory',
    title: domainByPath('inventory').label,
    loadChildren: () =>
      import('./features/inventory/inventory.routes').then((m) => m.INVENTORY_ROUTES),
  },
  {
    path: 'incidents',
    title: domainByPath('incidents').label,
    loadChildren: () =>
      import('./features/incidents/incidents.routes').then((m) => m.INCIDENTS_ROUTES),
  },
  { path: '**', title: 'Page not found', component: NotFoundPage },
];
