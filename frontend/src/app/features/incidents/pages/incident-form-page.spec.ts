import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { Router, provideRouter } from '@angular/router';

import { TEST_CONFIG, pageOf, provideTestConfig } from '../../../testing/test-config';
import { Colony } from '../../colonies/data/colony.service';
import { Incident } from '../data/incident.service';
import { IncidentFormPage } from './incident-form-page';

const INCIDENTS_URL = `${TEST_CONFIG.apiBaseUrl}/incidents`;
const COLONIES_URL = `${TEST_CONFIG.apiBaseUrl}/colonies`;

const ARES: Colony = {
  code: 'ARS-01',
  name: 'Ares Prime',
  status: 'OPERATIONAL',
  active: true,
  maxPopulation: 40,
  establishedAt: '2031-03-14',
};
const OLD: Colony = {
  ...ARES,
  code: 'OLD-01',
  name: 'Old Outpost',
  status: 'INACTIVE',
  active: false,
};

describe('IncidentFormPage', () => {
  let fixture: ComponentFixture<IncidentFormPage>;
  let http: HttpTestingController;
  let navigate: ReturnType<typeof vi.spyOn>;

  beforeEach(async () => {
    TestBed.configureTestingModule({
      providers: [
        provideHttpClient(),
        provideHttpClientTesting(),
        provideRouter([]),
        provideTestConfig(),
      ],
    });
    http = TestBed.inject(HttpTestingController);
    navigate = vi.spyOn(TestBed.inject(Router), 'navigate').mockResolvedValue(true);
    fixture = TestBed.createComponent(IncidentFormPage);

    const colonies = http.expectOne((r) => r.url === COLONIES_URL);
    expect(colonies.request.params.has('active')).toBe(false);
    colonies.flush(pageOf([ARES, OLD]));
    await fixture.whenStable();
  });

  afterEach(() => http.verify());

  const el = () => fixture.nativeElement as HTMLElement;

  function type(id: string, value: string): void {
    const input = el().querySelector<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>(
      `#${id}`,
    )!;
    input.value = value;
    input.dispatchEvent(new Event(input instanceof HTMLSelectElement ? 'change' : 'input'));
  }

  function fillRequired(): void {
    type('colonyCode', 'ARS-01');
    type('title', 'Airlock pressure drop');
    type('description', 'Pressure fell to 96 kPa.');
    type('severity', 'HIGH');
  }

  async function submit(): Promise<void> {
    el().querySelector<HTMLButtonElement>('button[type="submit"]')!.click();
    await fixture.whenStable();
  }

  it('offers every base and explains every severity', () => {
    const bases = Array.from(el().querySelectorAll('#colonyCode option')).map((o) =>
      o.textContent?.trim(),
    );
    expect(bases).toEqual(['Choose a base', 'ARS-01 · Ares Prime', 'OLD-01 · Old Outpost']);

    const severities = Array.from(el().querySelectorAll('#severity option')).map((o) =>
      o.textContent?.trim(),
    );
    expect(severities).toEqual([
      'Choose a severity',
      'Low: no impact on safety or operations',
      'Medium: degraded operations, no danger for the crew',
      'High: operations or crew at risk',
      'Critical: immediate danger for the crew or the base',
    ]);
  });

  it('does not call the server while required fields are missing', async () => {
    type('title', 'Something');
    await submit();

    http.expectNone(INCIDENTS_URL);
    for (const field of ['colonyCode', 'description', 'severity']) {
      expect(el().querySelector(`#${field}-error`)?.textContent).toContain('required');
    }
    expect(el().querySelector('#severity')?.getAttribute('aria-invalid')).toBe('true');
  });

  it('opens the incident and returns to the list', async () => {
    fillRequired();
    await submit();

    const req = http.expectOne(INCIDENTS_URL);
    expect(req.request.method).toBe('POST');
    expect(req.request.body).toEqual({
      colonyCode: 'ARS-01',
      title: 'Airlock pressure drop',
      description: 'Pressure fell to 96 kPa.',
      severity: 'HIGH',
    });
    const opened: Incident = {
      ...req.request.body,
      code: 'INC-0007',
      status: 'OPEN',
      reportedBy: 'mc.rossi',
      openedAt: '2040-03-01T10:15:30Z',
    };
    req.flush(opened, { status: 201, statusText: 'Created' });
    await fixture.whenStable();

    expect(navigate).toHaveBeenCalledWith(
      ['..'],
      expect.objectContaining({ queryParams: { created: 'INC-0007' } }),
    );
  });

  it('shows an unknown base on the base field', async () => {
    fillRequired();
    await submit();

    http
      .expectOne(INCIDENTS_URL)
      .flush(
        { status: 409, code: 'INCIDENT_COLONY_NOT_FOUND', detail: "Base 'ARS-01' does not exist." },
        { status: 409, statusText: 'Conflict' },
      );
    await fixture.whenStable();

    expect(navigate).not.toHaveBeenCalled();
    expect(el().querySelector('#colonyCode-error')?.textContent).toContain('does not exist');
    expect(el().querySelector<HTMLButtonElement>('button[type="submit"]')!.disabled).toBe(false);
  });

  it('shows failures that belong to no field above the form', async () => {
    fillRequired();
    await submit();

    http
      .expectOne(INCIDENTS_URL)
      .flush(
        { status: 503, code: 'SERVICE_UNAVAILABLE', detail: 'Database offline.' },
        { status: 503, statusText: 'Service Unavailable' },
      );
    await fixture.whenStable();

    expect(el().querySelector('[role="alert"]')?.textContent).toContain('Database offline.');
  });
});
