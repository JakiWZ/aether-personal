import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { Router, provideRouter } from '@angular/router';

import { TEST_CONFIG, pageOf, provideTestConfig } from '../../../testing/test-config';
import { Colony } from '../data/colony.service';
import { CrewMember } from '../data/crew-member.service';
import { CrewMemberFormPage } from './crew-member-form-page';

const CREW_URL = `${TEST_CONFIG.apiBaseUrl}/crew-members`;
const COLONIES_URL = `${TEST_CONFIG.apiBaseUrl}/colonies`;

const ARES: Colony = {
  code: 'ARS-01',
  name: 'Ares Prime',
  status: 'OPERATIONAL',
  active: true,
  maxPopulation: 40,
  establishedAt: '2031-03-14',
};

describe('CrewMemberFormPage', () => {
  let fixture: ComponentFixture<CrewMemberFormPage>;
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
    fixture = TestBed.createComponent(CrewMemberFormPage);

    const colonies = http.expectOne((r) => r.url === COLONIES_URL);
    expect(colonies.request.params.get('active')).toBe('true');
    expect(colonies.request.params.get('size')).toBe('100');
    colonies.flush(pageOf([ARES]));
    await fixture.whenStable();
  });

  afterEach(() => http.verify());

  const el = () => fixture.nativeElement as HTMLElement;

  function type(id: string, value: string): void {
    const input = el().querySelector<HTMLInputElement | HTMLSelectElement>(`#${id}`)!;
    input.value = value;
    input.dispatchEvent(new Event(input instanceof HTMLSelectElement ? 'change' : 'input'));
  }

  function fillRequired(): void {
    type('employeeCode', 'crw-042');
    type('firstName', 'Mae');
    type('lastName', 'Jemison');
    type('operationalRole', 'Medical officer');
  }

  async function submit(): Promise<void> {
    el().querySelector<HTMLButtonElement>('button[type="submit"]')!.click();
    await fixture.whenStable();
  }

  it('offers active bases only and leaves the base optional', () => {
    const options = Array.from(el().querySelectorAll('#homeColonyCode option'));

    expect(options.map((o) => o.textContent?.trim())).toEqual([
      'Not assigned',
      'ARS-01 · Ares Prime',
    ]);
  });

  it('does not call the server while required fields are missing', async () => {
    type('employeeCode', 'x!');
    await submit();

    http.expectNone(CREW_URL);
    expect(el().querySelector('#employeeCode-error')?.textContent).toContain('3 to 40 letters');
    expect(el().querySelector('#firstName-error')?.textContent).toContain('required');
    expect(el().querySelector('#employeeCode')?.getAttribute('aria-invalid')).toBe('true');
    expect(el().querySelector('#employeeCode')?.getAttribute('aria-describedby')).toBe(
      'employeeCode-error',
    );
  });

  it('registers the member and returns to the list', async () => {
    fillRequired();
    type('email', '  ');
    type('homeColonyCode', 'ARS-01');
    await submit();

    const req = http.expectOne(CREW_URL);
    expect(req.request.method).toBe('POST');
    expect(req.request.body).toEqual({
      employeeCode: 'crw-042',
      firstName: 'Mae',
      lastName: 'Jemison',
      email: null,
      operationalRole: 'Medical officer',
      status: 'ACTIVE',
      homeColonyCode: 'ARS-01',
    });
    const created: CrewMember = { ...req.request.body, employeeCode: 'CRW-042' };
    req.flush(created, { status: 201, statusText: 'Created' });
    await fixture.whenStable();

    expect(navigate).toHaveBeenCalledWith(
      ['..'],
      expect.objectContaining({ queryParams: { created: 'CRW-042' } }),
    );
  });

  it('shows a duplicate code on the employee code field', async () => {
    fillRequired();
    await submit();

    http.expectOne(CREW_URL).flush(
      {
        status: 409,
        code: 'CREW_MEMBER_CODE_TAKEN',
        detail: 'Employee code CRW-042 is already in use.',
      },
      { status: 409, statusText: 'Conflict' },
    );
    await fixture.whenStable();

    expect(navigate).not.toHaveBeenCalled();
    expect(el().querySelector('#employeeCode-error')?.textContent).toContain(
      'Employee code CRW-042 is already in use.',
    );
    expect(el().querySelector('[role="alert"]')).toBeNull();
    expect(el().querySelector<HTMLButtonElement>('button[type="submit"]')!.disabled).toBe(false);
  });

  it('maps server validation errors to their fields', async () => {
    fillRequired();
    await submit();

    http.expectOne(CREW_URL).flush(
      {
        status: 400,
        code: 'VALIDATION_FAILED',
        detail: 'Request validation failed.',
        errors: [{ field: 'lastName', message: 'must not be blank' }],
      },
      { status: 400, statusText: 'Bad Request' },
    );
    await fixture.whenStable();

    expect(el().querySelector('#lastName-error')?.textContent).toContain('must not be blank');
  });

  it('shows failures that belong to no field above the form', async () => {
    fillRequired();
    await submit();

    http
      .expectOne(CREW_URL)
      .flush(
        { status: 503, code: 'SERVICE_UNAVAILABLE', detail: 'Database offline.' },
        { status: 503, statusText: 'Service Unavailable' },
      );
    await fixture.whenStable();

    expect(el().querySelector('[role="alert"]')?.textContent).toContain('Database offline.');
  });
});
