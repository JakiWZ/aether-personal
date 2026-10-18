import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { Router, provideRouter } from '@angular/router';

import { TEST_CONFIG, pageOf, provideTestConfig } from '../../../testing/test-config';
import { Resource, UnitOfMeasure } from '../data/resource.service';
import { ResourceFormPage } from './resource-form-page';

const RESOURCES_URL = `${TEST_CONFIG.apiBaseUrl}/resources`;
const UNITS_URL = `${TEST_CONFIG.apiBaseUrl}/units-of-measure`;

const UNITS: UnitOfMeasure[] = [
  { code: 'KG', name: 'Kilogram', symbol: 'kg', quantityType: 'MASS' },
  { code: 'PCS', name: 'Pieces', symbol: 'pcs', quantityType: 'COUNT' },
];

describe('ResourceFormPage', () => {
  let fixture: ComponentFixture<ResourceFormPage>;
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
    fixture = TestBed.createComponent(ResourceFormPage);

    http.expectOne((r) => r.url === UNITS_URL).flush(pageOf(UNITS));
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
    type('code', 'co2_scrubber');
    type('name', 'CO2 scrubber cartridge');
    type('category', 'LIFE_SUPPORT');
    type('unitCode', 'PCS');
  }

  async function submit(): Promise<void> {
    el().querySelector<HTMLButtonElement>('button[type="submit"]')!.click();
    await fixture.whenStable();
  }

  it('offers the units from the server with no unit preselected', () => {
    const options = Array.from(el().querySelectorAll('#unitCode option'));

    expect(options.map((o) => o.textContent?.trim())).toEqual([
      'Choose a unit',
      'Kilogram (kg)',
      'Pieces (pcs)',
    ]);
    expect(el().querySelector<HTMLSelectElement>('#unitCode')!.value).toBe('');
  });

  it('does not call the server while the unit or other required fields are missing', async () => {
    type('code', 'x');
    type('name', 'Something');
    await submit();

    http.expectNone(RESOURCES_URL);
    expect(el().querySelector('#code-error')?.textContent).toContain('2 to 50 letters');
    expect(el().querySelector('#unitCode-error')?.textContent).toContain('required');
    expect(el().querySelector('#category-error')?.textContent).toContain('required');
    expect(el().querySelector('#unitCode')?.getAttribute('aria-invalid')).toBe('true');
  });

  it('adds the resource and returns to the list', async () => {
    fillRequired();
    el().querySelector<HTMLInputElement>('#critical')!.click();
    type('shelfLifeDays', '365');
    await submit();

    const req = http.expectOne(RESOURCES_URL);
    expect(req.request.method).toBe('POST');
    expect(req.request.body).toEqual({
      code: 'co2_scrubber',
      name: 'CO2 scrubber cartridge',
      category: 'LIFE_SUPPORT',
      unitCode: 'PCS',
      critical: true,
      shelfLifeDays: 365,
    });
    const created: Resource = {
      ...req.request.body,
      code: 'CO2_SCRUBBER',
      unitSymbol: 'pcs',
      active: true,
    };
    req.flush(created, { status: 201, statusText: 'Created' });
    await fixture.whenStable();

    expect(navigate).toHaveBeenCalledWith(
      ['..'],
      expect.objectContaining({ queryParams: { created: 'CO2_SCRUBBER' } }),
    );
  });

  it('sends no shelf life when left empty', async () => {
    fillRequired();
    await submit();

    const req = http.expectOne(RESOURCES_URL);
    expect(req.request.body.shelfLifeDays).toBeNull();
    expect(req.request.body.critical).toBe(false);
    req.flush({});
  });

  it('shows a duplicate code on the code field', async () => {
    fillRequired();
    await submit();

    http.expectOne(RESOURCES_URL).flush(
      {
        status: 409,
        code: 'RESOURCE_CODE_TAKEN',
        detail: "Resource code 'CO2_SCRUBBER' is already in use.",
      },
      { status: 409, statusText: 'Conflict' },
    );
    await fixture.whenStable();

    expect(navigate).not.toHaveBeenCalled();
    expect(el().querySelector('#code-error')?.textContent).toContain('already in use');
    expect(el().querySelector('[role="alert"]')).toBeNull();
  });

  it('shows failures that belong to no field above the form', async () => {
    fillRequired();
    await submit();

    http
      .expectOne(RESOURCES_URL)
      .flush(
        { status: 503, code: 'SERVICE_UNAVAILABLE', detail: 'Database offline.' },
        { status: 503, statusText: 'Service Unavailable' },
      );
    await fixture.whenStable();

    expect(el().querySelector('[role="alert"]')?.textContent).toContain('Database offline.');
  });
});

describe('ResourceFormPage without units', () => {
  it('says the units could not be loaded', async () => {
    TestBed.configureTestingModule({
      providers: [
        provideHttpClient(),
        provideHttpClientTesting(),
        provideRouter([]),
        provideTestConfig(),
      ],
    });
    const http = TestBed.inject(HttpTestingController);
    const fixture = TestBed.createComponent(ResourceFormPage);

    http
      .expectOne((r) => r.url === UNITS_URL)
      .flush({ status: 500, code: 'INTERNAL_ERROR' }, { status: 500, statusText: 'Error' });
    await fixture.whenStable();

    expect(
      (fixture.nativeElement as HTMLElement).querySelector('[role="alert"]')?.textContent,
    ).toContain('units of measure could not be loaded');
    http.verify();
  });
});
