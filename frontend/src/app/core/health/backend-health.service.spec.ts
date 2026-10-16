import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';

import { TEST_CONFIG, provideTestConfig } from '../../testing/test-config';
import { BackendHealth, BackendHealthService } from './backend-health.service';

describe('BackendHealthService', () => {
  let service: BackendHealthService;
  let http: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting(), provideTestConfig()],
    });
    service = TestBed.inject(BackendHealthService);
    http = TestBed.inject(HttpTestingController);
  });

  afterEach(() => http.verify());

  function check(): BackendHealth[] {
    const results: BackendHealth[] = [];
    service.check().subscribe((r) => results.push(r));
    return results;
  }

  it('calls the configured health URL and reports up', () => {
    const results = check();

    const req = http.expectOne(TEST_CONFIG.healthUrl);
    expect(req.request.method).toBe('GET');
    req.flush({ status: 'UP' });

    expect(results).toEqual(['up']);
  });

  it('reports down when actuator answers 503', () => {
    const results = check();

    http
      .expectOne(TEST_CONFIG.healthUrl)
      .flush({ status: 'DOWN' }, { status: 503, statusText: 'Service Unavailable' });

    expect(results).toEqual(['down']);
  });

  it('reports down when the body is not UP', () => {
    const results = check();

    http.expectOne(TEST_CONFIG.healthUrl).flush({ status: 'OUT_OF_SERVICE' });

    expect(results).toEqual(['down']);
  });

  it('reports unreachable on a network error', () => {
    const results = check();

    http.expectOne(TEST_CONFIG.healthUrl).error(new ProgressEvent('error'));

    expect(results).toEqual(['unreachable']);
  });

  it('reports unreachable when a proxy cannot reach the backend', () => {
    const results = check();

    http.expectOne(TEST_CONFIG.healthUrl).flush(null, { status: 502, statusText: 'Bad Gateway' });

    expect(results).toEqual(['unreachable']);
  });
});
