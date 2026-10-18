import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';

import {
  SIGNED_IN,
  TEST_CONFIG,
  pageOf,
  provideTestConfig,
  signIn,
} from '../../../testing/test-config';
import { Resource } from '../data/resource.service';
import { ResourceListPage } from './resource-list-page';

const URL = `${TEST_CONFIG.apiBaseUrl}/resources`;

const WATER: Resource = {
  code: 'WATER',
  name: 'Potable water',
  category: 'LIFE_SUPPORT',
  unitCode: 'L',
  unitSymbol: 'L',
  critical: true,
  active: true,
  shelfLifeDays: null,
};
const FILTER: Resource = {
  code: 'AIR_FILTER',
  name: 'HEPA air filter cartridge',
  category: 'SPARE_PART',
  unitCode: 'PCS',
  unitSymbol: 'pcs',
  critical: false,
  active: false,
  shelfLifeDays: null,
};

describe('ResourceListPage', () => {
  let fixture: ComponentFixture<ResourceListPage>;
  let http: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        provideHttpClient(),
        provideHttpClientTesting(),
        provideRouter([]),
        provideTestConfig(),
      ],
    });
    http = TestBed.inject(HttpTestingController);
    fixture = TestBed.createComponent(ResourceListPage);
  });

  afterEach(() => http.verify());

  const el = () => fixture.nativeElement as HTMLElement;
  const rows = () => Array.from(el().querySelectorAll('tbody tr'));
  const status = () => el().querySelector('[role="status"]')?.textContent;

  async function respond(body: Resource[]): Promise<void> {
    http.expectOne((r) => r.url === URL && r.method === 'GET').flush(pageOf(body));
    await fixture.whenStable();
  }

  it('shows a loading message until the resources arrive', async () => {
    await fixture.whenStable();

    expect(status()).toContain('Loading resources');
    await respond([WATER]);
    expect(el().textContent).not.toContain('Loading resources');
  });

  it('lists code, name, category, unit, criticality and activity', async () => {
    await respond([FILTER, WATER]);

    expect(rows().map((r) => r.querySelector('.code')?.textContent)).toEqual([
      'AIR_FILTER',
      'WATER',
    ]);
    for (const text of ['Potable water', 'Life support', 'L', 'Yes', 'Active']) {
      expect(rows()[1].textContent).toContain(text);
    }
    expect(rows()[0].classList).toContain('inactive');
    expect(rows()[0].querySelector('.activity')?.textContent?.trim()).toBe('Inactive');
  });

  it('shows an empty state for the catalogue and for each filter', async () => {
    await respond([]);
    expect(el().querySelector('table')).toBeNull();
    expect(status()).toContain('No resources in the catalogue yet');

    const select = el().querySelector<HTMLSelectElement>('#activity-filter')!;
    select.value = 'inactive';
    select.dispatchEvent(new Event('change'));
    const req = http.expectOne((r) => r.url === URL);
    expect(req.request.params.get('active')).toBe('false');
    req.flush(pageOf([]));
    await fixture.whenStable();

    expect(status()).toContain('No inactive resources');
  });

  it('shows the server error and retries on demand', async () => {
    http
      .expectOne((r) => r.url === URL)
      .flush(
        { status: 503, code: 'SERVICE_UNAVAILABLE', detail: 'Database offline.' },
        { status: 503, statusText: 'Service Unavailable' },
      );
    await fixture.whenStable();

    const alert = el().querySelector('[role="alert"]');
    expect(alert?.textContent).toContain('Database offline.');

    alert!.querySelector('button')!.click();
    await respond([WATER]);
    expect(rows()).toHaveLength(1);
  });

  it('offers creation and activity changes only to users allowed to manage the catalogue', async () => {
    const createLink = () =>
      Array.from(el().querySelectorAll('a')).find((a) => a.textContent === 'New resource');
    signIn({
      ...SIGNED_IN,
      permissions: SIGNED_IN.permissions.filter((p) => p !== 'INVENTORY_MANAGE'),
    });
    await respond([WATER]);
    expect(createLink()).toBeUndefined();
    expect(rows()[0].querySelector('button')).toBeNull();

    signIn();
    await fixture.whenStable();
    expect(createLink()?.getAttribute('href')).toBe('/new');
    expect(rows()[0].querySelector('button')?.textContent?.trim()).toBe('Deactivate');
  });

  it('deactivates a resource, announces it and reloads the list', async () => {
    signIn();
    await respond([WATER]);

    rows()[0].querySelector('button')!.click();
    await fixture.whenStable();
    expect(rows()[0].querySelector('button')?.textContent?.trim()).toBe('Saving…');

    const patch = http.expectOne(`${URL}/WATER`);
    expect(patch.request.method).toBe('PATCH');
    expect(patch.request.body).toEqual({ active: false });
    patch.flush({ ...WATER, active: false });
    await respond([{ ...WATER, active: false }]);

    expect(status()).toContain('Resource WATER deactivated.');
    expect(rows()[0].querySelector('button')?.textContent?.trim()).toBe('Reactivate');
  });

  it('keeps the list and shows why an activity change failed', async () => {
    signIn();
    await respond([FILTER]);

    rows()[0].querySelector('button')!.click();
    http
      .expectOne(`${URL}/AIR_FILTER`)
      .flush(
        { status: 403, code: 'ACCESS_DENIED', detail: 'Access denied.' },
        { status: 403, statusText: 'Forbidden' },
      );
    await fixture.whenStable();

    expect(el().querySelector('[role="alert"]')?.textContent).toContain(
      'Resource AIR_FILTER could not be changed.',
    );
    expect(rows()).toHaveLength(1);
    expect(rows()[0].querySelector('button')?.hasAttribute('disabled')).toBe(false);
  });
});
