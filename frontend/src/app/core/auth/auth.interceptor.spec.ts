import { HttpClient, provideHttpClient, withInterceptors } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';
import { Router, provideRouter } from '@angular/router';

import { TEST_CONFIG, provideTestConfig, signIn } from '../../testing/test-config';
import { authInterceptor } from './auth.interceptor';
import { AuthService } from './auth.service';

describe('authInterceptor', () => {
  let http: HttpTestingController;
  let navigate: ReturnType<typeof vi.spyOn>;
  const missions = `${TEST_CONFIG.apiBaseUrl}/missions`;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        provideHttpClient(withInterceptors([authInterceptor])),
        provideHttpClientTesting(),
        provideRouter([]),
        provideTestConfig(),
      ],
    });
    http = TestBed.inject(HttpTestingController);
    navigate = vi.spyOn(TestBed.inject(Router), 'navigate').mockResolvedValue(true);
    signIn();
  });

  afterEach(() => http.verify());

  const unauthorized = { status: 401, statusText: 'Unauthorized' };

  it('signs the user out and shows the login page when the session has expired', () => {
    let failed = false;
    TestBed.inject(HttpClient)
      .get(missions)
      .subscribe({ error: () => (failed = true) });
    http.expectOne(missions).flush({ status: 401, code: 'AUTHENTICATION_REQUIRED' }, unauthorized);

    expect(failed).toBe(true);
    expect(TestBed.inject(AuthService).authenticated()).toBe(false);
    expect(navigate).toHaveBeenCalledWith(['/login'], { queryParams: { returnUrl: '/' } });
  });

  it('leaves a refused login to the login page', () => {
    const login = `${TEST_CONFIG.apiBaseUrl}/auth/login`;
    TestBed.inject(HttpClient)
      .post(login, {})
      .subscribe({ error: () => undefined });
    http.expectOne(login).flush({ status: 401, code: 'INVALID_CREDENTIALS' }, unauthorized);

    expect(navigate).not.toHaveBeenCalled();
  });

  it('ignores other errors', () => {
    TestBed.inject(HttpClient)
      .get(missions)
      .subscribe({ error: () => undefined });
    http.expectOne(missions).flush({}, { status: 403, statusText: 'Forbidden' });

    expect(TestBed.inject(AuthService).authenticated()).toBe(true);
    expect(navigate).not.toHaveBeenCalled();
  });
});
