import { Routes } from '@angular/router';

import { FeaturePlaceholder } from '../../shared/ui/feature-placeholder/feature-placeholder';

export const MISSIONS_ROUTES: Routes = [
  { path: '', component: FeaturePlaceholder, data: { domain: 'missions' } },
];
