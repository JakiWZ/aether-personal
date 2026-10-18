import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';

import { TEST_CONFIG, pageOf, provideTestConfig } from '../../../testing/test-config';
import { ResourceService } from './resource.service';

const URL = `${TEST_CONFIG.apiBaseUrl}/resources`;

describe('ResourceService', () => {
  let service: ResourceService;
  let http: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting(), provideTestConfig()],
    });
    service = TestBed.inject(ResourceService);
    http = TestBed.inject(HttpTestingController);
  });

  afterEach(() => http.verify());

  it('lists resources with the active filter only when given', () => {
    service.list().subscribe();
    const all = http.expectOne((r) => r.url === URL);
    expect(all.request.params.has('active')).toBe(false);
    expect(all.request.params.get('size')).toBe('20');
    all.flush(pageOf([]));

    service.list(false, 1).subscribe();
    const inactive = http.expectOne((r) => r.url === URL);
    expect(inactive.request.params.get('active')).toBe('false');
    expect(inactive.request.params.get('page')).toBe('1');
    inactive.flush(pageOf([]));
  });

  it('creates a resource with a POST', () => {
    service
      .create({
        code: 'CO2_SCRUBBER',
        name: 'CO2 scrubber',
        category: 'LIFE_SUPPORT',
        unitCode: 'PCS',
        critical: true,
        shelfLifeDays: null,
      })
      .subscribe();

    const req = http.expectOne(URL);
    expect(req.request.method).toBe('POST');
    expect(req.request.body.unitCode).toBe('PCS');
    req.flush({});
  });

  it('changes the activity with a PATCH on the encoded code', () => {
    service.setActive('A/B', false).subscribe();

    const req = http.expectOne(`${URL}/A%2FB`);
    expect(req.request.method).toBe('PATCH');
    expect(req.request.body).toEqual({ active: false });
    req.flush({});
  });

  it('asks for every unit of measure in one page', () => {
    service.units().subscribe();

    const req = http.expectOne((r) => r.url === `${TEST_CONFIG.apiBaseUrl}/units-of-measure`);
    expect(req.request.params.get('size')).toBe('100');
    req.flush(pageOf([]));
  });
});
