import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { Router, provideRouter } from '@angular/router';

import { TEST_CONFIG, provideTestConfig } from '../../../testing/test-config';
import { Colony } from '../../colonies/data/colony.service';
import { MissionFormPage } from './mission-form-page';

const MISSIONS_URL = `${TEST_CONFIG.apiBaseUrl}/missions`;
const COLONIES_URL = `${TEST_CONFIG.apiBaseUrl}/colonies`;

const ARES: Colony = {
  code: 'ARS-01',
  name: 'Ares Prime',
  status: 'OPERATIONAL',
  active: true,
  maxPopulation: 40,
  establishedAt: '2031-03-14',
};

describe('MissionFormPage', () => {
  let fixture: ComponentFixture<MissionFormPage>;
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
    fixture = TestBed.createComponent(MissionFormPage);

    const colonies = http.expectOne((r) => r.url === COLONIES_URL);
    expect(colonies.request.params.get('active')).toBe('true');
    colonies.flush([ARES]);
    await fixture.whenStable();
  });

  afterEach(() => http.verify());

  const el = () => fixture.nativeElement as HTMLElement;
  const error = (id: string) => el().querySelector(`#${id}-error`)?.textContent;

  function type(id: string, value: string): void {
    const input = el().querySelector<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>(
      `#${id}`,
    )!;
    input.value = value;
    input.dispatchEvent(new Event(input instanceof HTMLSelectElement ? 'change' : 'input'));
  }

  function fillRequired(): void {
    type('code', 'phx-020');
    type('title', 'Jezero delta survey');
    type('objective', 'Map the delta front');
    type('type', 'EXPLORATION');
    type('originColonyCode', 'ARS-01');
    type('plannedStartAt', '2099-05-01T08:00');
    type('plannedEndAt', '2099-05-03T18:00');
  }

  async function submit(): Promise<void> {
    el().querySelector<HTMLButtonElement>('button[type="submit"]')!.click();
    await fixture.whenStable();
  }

  it('offers active bases and the documented priorities and risk levels', () => {
    const options = (id: string) =>
      Array.from(el().querySelectorAll(`#${id} option`)).map((o) => o.textContent?.trim());

    expect(options('originColonyCode')).toEqual(['Choose an active base', 'ARS-01 · Ares Prime']);
    expect(options('priority')).toEqual(['Low', 'Medium', 'High', 'Critical']);
    expect(options('safetyLevel')).toEqual(['Standard', 'Elevated', 'High risk', 'Critical']);
  });

  it('does not call the server while required fields are missing', async () => {
    type('code', 'x!');
    await submit();

    http.expectNone(MISSIONS_URL);
    expect(error('code')).toContain('3 to 60 letters');
    expect(error('objective')).toContain('required');
    expect(error('originColonyCode')).toContain('required');
    expect(el().querySelector('#code')?.getAttribute('aria-invalid')).toBe('true');
  });

  it('rejects an end that does not follow the start before calling the server', async () => {
    fillRequired();
    type('plannedEndAt', '2099-05-01T08:00');
    await submit();

    http.expectNone(MISSIONS_URL);
    expect(error('plannedEndAt')).toContain('The end must be after the start.');
    expect(el().querySelector('#plannedEndAt')?.getAttribute('aria-describedby')).toBe(
      'plannedEndAt-error',
    );
  });

  it('drafts the mission with UTC instants and returns to the list', async () => {
    fillRequired();
    await submit();

    const req = http.expectOne(MISSIONS_URL);
    expect(req.request.method).toBe('POST');
    expect(req.request.body).toEqual({
      code: 'phx-020',
      title: 'Jezero delta survey',
      objective: 'Map the delta front',
      description: null,
      type: 'EXPLORATION',
      originColonyCode: 'ARS-01',
      plannedStartAt: '2099-05-01T08:00:00Z',
      plannedEndAt: '2099-05-03T18:00:00Z',
      priority: 'MEDIUM',
      safetyLevel: 'STANDARD',
    });
    req.flush({ code: 'PHX-020', status: 'DRAFT' }, { status: 201, statusText: 'Created' });
    await fixture.whenStable();

    expect(navigate).toHaveBeenCalledWith(
      ['..'],
      expect.objectContaining({ queryParams: { created: 'PHX-020' } }),
    );
  });

  it('shows a duplicate code on the code field', async () => {
    fillRequired();
    await submit();

    http.expectOne(MISSIONS_URL).flush(
      {
        status: 409,
        code: 'MISSION_CODE_TAKEN',
        detail: "Mission code 'PHX-020' is already in use.",
      },
      { status: 409, statusText: 'Conflict' },
    );
    await fixture.whenStable();

    expect(navigate).not.toHaveBeenCalled();
    expect(error('code')).toContain("Mission code 'PHX-020' is already in use.");
    expect(el().querySelector('[role="alert"]')).toBeNull();
    expect(el().querySelector<HTMLButtonElement>('button[type="submit"]')!.disabled).toBe(false);
  });

  it('shows an unusable base on the base field', async () => {
    fillRequired();
    await submit();

    http
      .expectOne(MISSIONS_URL)
      .flush(
        { status: 409, code: 'ORIGIN_COLONY_INACTIVE', detail: "Base 'ARS-01' is not active." },
        { status: 409, statusText: 'Conflict' },
      );
    await fixture.whenStable();

    expect(error('originColonyCode')).toContain("Base 'ARS-01' is not active.");
  });

  it('maps a start in the past reported by the server to its field', async () => {
    fillRequired();
    await submit();

    http.expectOne(MISSIONS_URL).flush(
      {
        status: 400,
        code: 'VALIDATION_FAILED',
        detail: 'The request contains invalid values.',
        errors: [
          { field: 'plannedStartAt', message: 'must be a date in the present or in the future' },
        ],
      },
      { status: 400, statusText: 'Bad Request' },
    );
    await fixture.whenStable();

    expect(error('plannedStartAt')).toContain('must be a date in the present or in the future');
  });

  it('shows failures that belong to no field above the form', async () => {
    fillRequired();
    await submit();

    http
      .expectOne(MISSIONS_URL)
      .flush(
        { status: 503, code: 'SERVICE_UNAVAILABLE', detail: 'Database offline.' },
        { status: 503, statusText: 'Service Unavailable' },
      );
    await fixture.whenStable();

    expect(el().querySelector('[role="alert"]')?.textContent).toContain('Database offline.');
  });
});
