import { Routes } from '@angular/router';

import { MissionFormPage } from './pages/mission-form-page';
import { MissionListPage } from './pages/mission-list-page';

export const MISSIONS_ROUTES: Routes = [
  { path: '', title: 'Missions', component: MissionListPage },
  { path: 'new', title: 'New mission', component: MissionFormPage },
];
