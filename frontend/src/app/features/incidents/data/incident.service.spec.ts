import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';

import { TEST_CONFIG, pageOf, provideTestConfig } from '../../../testing/test-config';
import { IncidentService } from './incident.service';

const URL = `${TEST_CONFIG.apiBaseUrl}/incidents`;

describe('IncidentService', () => {
  let service: IncidentService;
  let http: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting(), provideTestConfig()],
    });
    service = TestBed.inject(IncidentService);
    http = TestBed.inject(HttpTestingController);
  });

  afterEach(() => http.verify());

  it('gets one page of incidents from the configured API URL', () => {
    service.list(2).subscribe();

    const req = http.expectOne((r) => r.url === URL);
    expect(req.request.method).toBe('GET');
    expect(req.request.params.get('page')).toBe('2');
    expect(req.request.params.get('size')).toBe('20');
    req.flush(pageOf([]));
  });

  it('opens an incident with a POST', () => {
    service
      .open({ colonyCode: 'ARS-01', title: 'Leak', description: 'Hiss', severity: 'HIGH' })
      .subscribe();

    const req = http.expectOne(URL);
    expect(req.request.method).toBe('POST');
    expect(req.request.body.severity).toBe('HIGH');
    req.flush({});
  });
});
