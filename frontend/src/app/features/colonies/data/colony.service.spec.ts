import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';

import { TEST_CONFIG, pageOf, provideTestConfig } from '../../../testing/test-config';
import { Colony, ColonyService } from './colony.service';

describe('ColonyService', () => {
  let service: ColonyService;
  let http: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting(), provideTestConfig()],
    });
    service = TestBed.inject(ColonyService);
    http = TestBed.inject(HttpTestingController);
  });

  afterEach(() => http.verify());

  it('gets the first page of bases from the configured API URL', () => {
    const colonies: Colony[] = [];
    service.list().subscribe((page) => colonies.push(...page.items));

    const req = http.expectOne((r) => r.url === `${TEST_CONFIG.apiBaseUrl}/colonies`);
    expect(req.request.method).toBe('GET');
    expect(req.request.params.has('active')).toBe(false);
    expect(req.request.params.get('page')).toBe('0');
    expect(req.request.params.get('size')).toBe('20');
    req.flush(
      pageOf([
        {
          code: 'ARS-01',
          name: 'Ares Prime',
          status: 'OPERATIONAL',
          active: true,
          maxPopulation: 40,
          establishedAt: '2031-03-14',
        },
      ]),
    );

    expect(colonies.map((c) => c.code)).toEqual(['ARS-01']);
  });

  it('sends the active filter when given', () => {
    service.list(false).subscribe();

    const req = http.expectOne((r) => r.url === `${TEST_CONFIG.apiBaseUrl}/colonies`);
    expect(req.request.params.get('active')).toBe('false');
    req.flush(pageOf([]));
  });
});
