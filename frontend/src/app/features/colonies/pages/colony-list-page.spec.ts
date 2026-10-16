import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { ComponentFixture, TestBed } from '@angular/core/testing';

import { TEST_CONFIG, provideTestConfig } from '../../../testing/test-config';
import { Colony } from '../data/colony.service';
import { ColonyListPage } from './colony-list-page';

const URL = `${TEST_CONFIG.apiBaseUrl}/colonies`;

const ARES: Colony = {
  code: 'ARS-01',
  name: 'Ares Prime',
  status: 'OPERATIONAL',
  active: true,
  maxPopulation: 40,
  establishedAt: '2031-03-14',
};
const OLD: Colony = {
  code: 'OLD-01',
  name: 'Old Outpost',
  status: 'INACTIVE',
  active: false,
  maxPopulation: null,
  establishedAt: null,
};

describe('ColonyListPage', () => {
  let fixture: ComponentFixture<ColonyListPage>;
  let http: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting(), provideTestConfig()],
    });
    http = TestBed.inject(HttpTestingController);
    fixture = TestBed.createComponent(ColonyListPage);
  });

  afterEach(() => http.verify());

  const el = () => fixture.nativeElement as HTMLElement;
  const rows = () => Array.from(el().querySelectorAll('tbody tr'));

  async function respond(body: Colony[]): Promise<void> {
    http.expectOne((r) => r.url === URL).flush(body);
    await fixture.whenStable();
  }

  it('shows a loading message until the bases arrive', async () => {
    await fixture.whenStable();

    expect(el().querySelector('[role="status"]')?.textContent).toContain('Loading bases');
    await respond([ARES]);
    expect(el().textContent).not.toContain('Loading bases');
  });

  it('lists code, name and status of every base and marks inactive ones', async () => {
    await respond([ARES, OLD]);

    expect(rows().map((r) => r.querySelector('.code')?.textContent)).toEqual(['ARS-01', 'OLD-01']);
    expect(rows()[0].textContent).toContain('Ares Prime');
    expect(rows()[0].textContent).toContain('Operational');
    expect(rows()[0].querySelector('.activity')?.textContent?.trim()).toBe('Active');
    expect(rows()[1].classList).toContain('inactive');
    expect(rows()[1].querySelector('.activity')?.textContent?.trim()).toBe('Inactive');
  });

  it('shows an empty state when no base is registered', async () => {
    await respond([]);

    expect(el().querySelector('table')).toBeNull();
    expect(el().querySelector('[role="status"]')?.textContent).toContain('No bases registered yet');
  });

  it('asks the server for inactive bases only when filtered', async () => {
    await respond([ARES, OLD]);

    const select = el().querySelector<HTMLSelectElement>('#activity-filter')!;
    select.value = 'inactive';
    select.dispatchEvent(new Event('change'));

    const req = http.expectOne((r) => r.url === URL);
    expect(req.request.params.get('active')).toBe('false');
    req.flush([]);
    await fixture.whenStable();

    expect(el().querySelector('[role="status"]')?.textContent).toContain('No inactive bases');
  });

  it('shows the server error and retries on demand', async () => {
    http
      .expectOne(URL)
      .flush(
        { status: 503, code: 'SERVICE_UNAVAILABLE', detail: 'Database offline.' },
        { status: 503, statusText: 'Service Unavailable' },
      );
    await fixture.whenStable();

    const alert = el().querySelector('[role="alert"]');
    expect(alert?.textContent).toContain('Database offline.');

    alert!.querySelector('button')!.click();
    await respond([ARES]);

    expect(el().querySelector('[role="alert"]')).toBeNull();
    expect(rows()).toHaveLength(1);
  });
});
