import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';

import { SIGNED_IN, TEST_CONFIG, provideTestConfig } from '../../testing/test-config';
import { ANONYMOUS, AuthService } from './auth.service';

describe('AuthService', () => {
  let auth: AuthService;
  let http: HttpTestingController;
  const url = `${TEST_CONFIG.apiBaseUrl}/auth`;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting(), provideTestConfig()],
    });
    auth = TestBed.inject(AuthService);
    http = TestBed.inject(HttpTestingController);
  });

  afterEach(() => http.verify());

  it('starts anonymous and learns the user from the configured session URL', () => {
    expect(auth.authenticated()).toBe(false);

    auth.refresh().subscribe();
    http.expectOne(`${url}/session`).flush(SIGNED_IN);

    expect(auth.authenticated()).toBe(true);
    expect(auth.hasPermission('MISSION_MANAGE')).toBe(true);
  });

  it('treats an unreachable server as nobody signed in', () => {
    let result: unknown;
    auth.refresh().subscribe((session) => (result = session));
    http.expectOne(`${url}/session`).error(new ProgressEvent('error'));

    expect(result).toEqual(ANONYMOUS);
    expect(auth.authenticated()).toBe(false);
  });

  it('fetches the CSRF cookie, then posts the credentials', () => {
    auth.login('mc.rossi', 'Aether-demo-password').subscribe();

    http.expectOne(`${url}/session`).flush(ANONYMOUS);
    const login = http.expectOne(`${url}/login`);
    expect(login.request.method).toBe('POST');
    expect(login.request.body).toEqual({ username: 'mc.rossi', password: 'Aether-demo-password' });
    login.flush(SIGNED_IN);

    expect(auth.session().displayName).toBe('Laura Rossi');
  });

  it('stays anonymous when the credentials are refused', () => {
    let failed = false;
    auth.login('mc.rossi', 'wrong').subscribe({ error: () => (failed = true) });

    http.expectOne(`${url}/session`).flush(ANONYMOUS);
    http
      .expectOne(`${url}/login`)
      .flush(
        { status: 401, code: 'INVALID_CREDENTIALS' },
        { status: 401, statusText: 'Unauthorized' },
      );

    expect(failed).toBe(true);
    expect(auth.authenticated()).toBe(false);
  });

  it('forgets the user on logout even if the server does not answer', () => {
    auth.refresh().subscribe();
    http.expectOne(`${url}/session`).flush(SIGNED_IN);

    auth.logout().subscribe();
    const logout = http.expectOne(`${url}/logout`);
    expect(logout.request.method).toBe('POST');
    logout.error(new ProgressEvent('error'));

    expect(auth.authenticated()).toBe(false);
  });
});
