import { Routes } from '@angular/router';

import { permissionGuard } from '../../core/auth/auth.guard';

import { IncidentFormPage } from './pages/incident-form-page';
import { IncidentListPage } from './pages/incident-list-page';

export const INCIDENTS_ROUTES: Routes = [
  { path: '', title: 'Incidents', component: IncidentListPage },
  {
    path: 'new',
    title: 'Report an incident',
    canMatch: [permissionGuard('INCIDENT_REPORT', '/incidents')],
    component: IncidentFormPage,
  },
];
