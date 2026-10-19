import { Routes } from '@angular/router';

import { permissionGuard } from '../../core/auth/auth.guard';

import { ResourceFormPage } from './pages/resource-form-page';
import { ResourceListPage } from './pages/resource-list-page';

export const INVENTORY_ROUTES: Routes = [
  { path: '', title: 'Resources', component: ResourceListPage },
  {
    path: 'new',
    title: 'New resource',
    canMatch: [permissionGuard('INVENTORY_MANAGE', '/inventory')],
    component: ResourceFormPage,
  },
];
