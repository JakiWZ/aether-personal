import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { ComponentFixture, TestBed } from '@angular/core/testing';

import { TEST_CONFIG, pageOf, provideTestConfig } from '../../../testing/test-config';
import { Vehicle } from '../data/vehicle.service';
import { VehicleListPage } from './vehicle-list-page';

const URL = `${TEST_CONFIG.apiBaseUrl}/vehicles`;

const ROVER: Vehicle = {
  code: 'ROV-ARS-01',
  typeCode: 'ROVER',
  typeName: 'Pressurised rover',
  manufacturer: 'RedRock Mobility',
  model: 'Pathfinder X2',
  serialNumber: 'SN-RV-1001',
  status: 'IN_USE',
  criticality: 'HIGH',
  colonyCode: 'ARS-01',
  active: true,
  commissionedAt: '2031-05-01',
  operatingHours: 4120.5,
};
const OLD: Vehicle = {
  ...ROVER,
  code: 'ROV-OLD-01',
  model: null,
  status: 'DECOMMISSIONED',
  criticality: 'LOW',
  active: false,
};

describe('VehicleListPage', () => {
  let fixture: ComponentFixture<VehicleListPage>;
  let http: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting(), provideTestConfig()],
    });
    http = TestBed.inject(HttpTestingController);
    fixture = TestBed.createComponent(VehicleListPage);
  });

  afterEach(() => http.verify());

  const el = () => fixture.nativeElement as HTMLElement;
  const rows = () => Array.from(el().querySelectorAll('tbody tr'));

  async function respond(body: Vehicle[]): Promise<void> {
    http.expectOne((r) => r.url === URL).flush(pageOf(body));
    await fixture.whenStable();
  }

  function selectStatus(value: string): void {
    const select = el().querySelector<HTMLSelectElement>('#status-filter')!;
    select.value = value;
    select.dispatchEvent(new Event('change'));
  }

  it('shows a loading message until the vehicles arrive', async () => {
    await fixture.whenStable();

    expect(el().querySelector('[role="status"]')?.textContent).toContain('Loading vehicles');
    await respond([ROVER]);
    expect(el().textContent).not.toContain('Loading vehicles');
  });

  it('lists type, model, base, criticality and status and keeps retired vehicles', async () => {
    await respond([ROVER, OLD]);

    expect(rows().map((r) => r.querySelector('.code')?.textContent)).toEqual([
      'ROV-ARS-01',
      'ROV-OLD-01',
    ]);
    const first = rows()[0].textContent;
    for (const text of ['Pressurised rover', 'Pathfinder X2', 'ARS-01', 'High', 'In use']) {
      expect(first).toContain(text);
    }
    expect(rows()[1].classList).toContain('inactive');
    expect(rows()[1].textContent).toContain('Decommissioned');
    expect(rows()[1].textContent).toContain('—');
  });

  it('offers every status as a filter', async () => {
    await respond([]);

    const options = Array.from(el().querySelectorAll('#status-filter option')).map((o) =>
      o.textContent?.trim(),
    );
    expect(options).toEqual([
      'All statuses',
      'Available',
      'In use',
      'Maintenance',
      'Out of service',
      'Decommissioned',
    ]);
  });

  it('shows an empty state when no vehicle is registered', async () => {
    await respond([]);

    expect(el().querySelector('table')).toBeNull();
    expect(el().querySelector('[role="status"]')?.textContent).toContain(
      'No vehicles registered yet',
    );
  });

  it('asks the server for one status and says when nothing matches', async () => {
    await respond([ROVER, OLD]);

    selectStatus('OUT_OF_SERVICE');
    const req = http.expectOne((r) => r.url === URL);
    expect(req.request.params.get('status')).toBe('OUT_OF_SERVICE');
    expect(req.request.params.get('page')).toBe('0');
    req.flush(pageOf([]));
    await fixture.whenStable();

    expect(el().querySelector('[role="status"]')?.textContent).toContain(
      'No vehicles with status Out of service',
    );

    selectStatus('all');
    const all = http.expectOne((r) => r.url === URL);
    expect(all.request.params.has('status')).toBe(false);
    all.flush(pageOf([ROVER]));
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
    await respond([ROVER]);

    expect(el().querySelector('[role="alert"]')).toBeNull();
    expect(rows()).toHaveLength(1);
  });
});
