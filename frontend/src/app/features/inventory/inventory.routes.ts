import { Routes } from '@angular/router';

import { FeaturePlaceholder } from '../../shared/ui/feature-placeholder/feature-placeholder';

export const INVENTORY_ROUTES: Routes = [
  { path: '', component: FeaturePlaceholder, data: { domain: 'inventory' } },
];
