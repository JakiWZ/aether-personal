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
import { Incident } from '../data/incident.service';
import { IncidentListPage } from './incident-list-page';

const URL = `${TEST_CONFIG.apiBaseUrl}/incidents`;

const AIRLOCK: Incident = {
  code: 'INC-0007',
  title: 'Airlock pressure drop',
  description: 'Pressure fell to 96 kPa.',
  severity: 'HIGH',
  status: 'OPEN',
  colonyCode: 'ARS-01',
  reportedBy: 'crew.conti',
  openedAt: '2040-03-01T10:15:30Z',
};

describe('IncidentListPage', () => {
  let fixture: ComponentFixture<IncidentListPage>;
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
    fixture = TestBed.createComponent(IncidentListPage);
  });

  afterEach(() => http.verify());

  const el = () => fixture.nativeElement as HTMLElement;
  const rows = () => Array.from(el().querySelectorAll('tbody tr'));

  async function respond(body: Incident[]): Promise<void> {
    http.expectOne((r) => r.url === URL).flush(pageOf(body));
    await fixture.whenStable();
  }

  it('shows a loading message until the incidents arrive', async () => {
    await fixture.whenStable();

    expect(el().querySelector('[role="status"]')?.textContent).toContain('Loading incidents');
    await respond([AIRLOCK]);
    expect(el().textContent).not.toContain('Loading incidents');
  });

  it('lists code, title, base, severity, status, opening time in UTC and reporter', async () => {
    await respond([AIRLOCK]);

    const row = rows()[0];
    expect(row.querySelector('.code')?.textContent).toBe('INC-0007');
    for (const text of ['Airlock pressure drop', 'ARS-01', 'High', 'Open', 'crew.conti']) {
      expect(row.textContent).toContain(text);
    }
    const time = row.querySelector('time')!;
    expect(time.getAttribute('datetime')).toBe('2040-03-01T10:15:30Z');
    expect(time.textContent).toBe('2040-03-01 10:15');
  });

  it('shows an empty state when no incident is reported', async () => {
    await respond([]);

    expect(el().querySelector('table')).toBeNull();
    expect(el().querySelector('[role="status"]')?.textContent).toContain('No incidents reported');
  });

  it('highlights the incident just opened', async () => {
    fixture.componentRef.setInput('created', 'INC-0007');
    await respond([AIRLOCK]);

    expect(el().querySelector('.success')?.textContent).toContain('Incident INC-0007 opened.');
    expect(rows()[0].classList).toContain('highlight');
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
    await respond([AIRLOCK]);
    expect(rows()).toHaveLength(1);
  });

  it('offers reporting only to users allowed to do it', async () => {
    const reportLink = () =>
      Array.from(el().querySelectorAll('a')).find((a) => a.textContent === 'Report an incident');
    signIn({
      ...SIGNED_IN,
      permissions: SIGNED_IN.permissions.filter((p) => p !== 'INCIDENT_REPORT'),
    });
    await respond([]);
    expect(reportLink()).toBeUndefined();

    signIn();
    await fixture.whenStable();
    expect(reportLink()?.getAttribute('href')).toBe('/new');
  });
});
