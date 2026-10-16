import { Routes } from '@angular/router';

import { ColoniesLayout } from './colonies-layout';
import { ColonyListPage } from './pages/colony-list-page';
import { CrewListPage } from './pages/crew-list-page';
import { CrewMemberFormPage } from './pages/crew-member-form-page';

export const COLONIES_ROUTES: Routes = [
  {
    path: '',
    component: ColoniesLayout,
    children: [
      { path: '', title: 'Bases', component: ColonyListPage },
      { path: 'crew', title: 'Crew', component: CrewListPage },
      { path: 'crew/new', title: 'New crew member', component: CrewMemberFormPage },
    ],
  },
];
