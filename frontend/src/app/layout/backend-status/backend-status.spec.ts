import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';

import { TEST_CONFIG, provideTestConfig } from '../../testing/test-config';
import { BackendStatus } from './backend-status';

describe('BackendStatus', () => {
  let http: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [BackendStatus],
      providers: [provideHttpClient(), provideHttpClientTesting(), provideTestConfig()],
    });
    http = TestBed.inject(HttpTestingController);
  });

  afterEach(() => http.verify());

  it('shows loading, then the healthy state without a retry button', async () => {
    const fixture = TestBed.createComponent(BackendStatus);
    await fixture.whenStable();
    const el = fixture.nativeElement as HTMLElement;
    expect(el.textContent).toContain('Checking backend');

    http.expectOne(TEST_CONFIG.healthUrl).flush({ status: 'UP' });
    await fixture.whenStable();

    expect(el.querySelector('[role="status"]')?.textContent).toContain('Backend online');
    expect(el.querySelector('button')).toBeNull();
  });

  it('offers a retry when the backend is unreachable', async () => {
    const fixture = TestBed.createComponent(BackendStatus);
    const el = fixture.nativeElement as HTMLElement;

    http.expectOne(TEST_CONFIG.healthUrl).error(new ProgressEvent('error'));
    await fixture.whenStable();
    expect(el.textContent).toContain('Backend unreachable');

    el.querySelector('button')!.click();
    http.expectOne(TEST_CONFIG.healthUrl).flush({ status: 'UP' });
    await fixture.whenStable();

    expect(el.textContent).toContain('Backend online');
  });
});
