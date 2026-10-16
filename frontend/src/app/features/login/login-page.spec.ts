import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { Router, provideRouter } from '@angular/router';

import { ANONYMOUS, AuthService } from '../../core/auth/auth.service';
import { SIGNED_IN, TEST_CONFIG, provideTestConfig } from '../../testing/test-config';
import { LoginPage } from './login-page';

describe('LoginPage', () => {
  let fixture: ComponentFixture<LoginPage>;
  let http: HttpTestingController;
  let navigate: ReturnType<typeof vi.spyOn>;
  const url = `${TEST_CONFIG.apiBaseUrl}/auth`;

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
    navigate = vi.spyOn(TestBed.inject(Router), 'navigateByUrl').mockResolvedValue(true);
    fixture = TestBed.createComponent(LoginPage);
    await fixture.whenStable();
  });

  afterEach(() => http.verify());

  const el = () => fixture.nativeElement as HTMLElement;
  const input = (id: string) => el().querySelector<HTMLInputElement>(`#${id}`)!;

  async function submit(username: string, password: string): Promise<void> {
    input('username').value = username;
    input('username').dispatchEvent(new Event('input'));
    input('password').value = password;
    input('password').dispatchEvent(new Event('input'));
    el().querySelector('form')!.dispatchEvent(new Event('submit'));
    await fixture.whenStable();
  }

  function answerLogin(status: number, body: object): void {
    http.expectOne(`${url}/session`).flush(ANONYMOUS);
    http
      .expectOne(`${url}/login`)
      .flush(body, { status, statusText: status === 200 ? 'OK' : 'Unauthorized' });
  }

  it('labels its fields for assistive technology and password managers', () => {
    expect(el().querySelector('label[for="username"]')?.textContent).toBe('Username');
    expect(input('username').getAttribute('autocomplete')).toBe('username');
    expect(input('password').type).toBe('password');
    expect(input('password').getAttribute('autocomplete')).toBe('current-password');
  });

  it('asks for both fields before calling the server', async () => {
    await submit('', '');

    expect(el().querySelector('#username-error')?.textContent).toContain('Enter your username');
    expect(el().querySelector('#password-error')?.textContent).toContain('Enter your password');
    expect(input('username').getAttribute('aria-invalid')).toBe('true');
  });

  it('signs in and goes back to the page the user wanted', async () => {
    fixture.componentRef.setInput('returnUrl', '/missions');
    await submit('mc.rossi', 'Aether-demo-password');
    answerLogin(200, SIGNED_IN);
    await fixture.whenStable();

    expect(TestBed.inject(AuthService).authenticated()).toBe(true);
    expect(navigate).toHaveBeenCalledWith('/missions');
  });

  it('never follows a return URL to another site', async () => {
    fixture.componentRef.setInput('returnUrl', '//evil.example');
    await submit('mc.rossi', 'Aether-demo-password');
    answerLogin(200, SIGNED_IN);
    await fixture.whenStable();

    expect(navigate).toHaveBeenCalledWith('/dashboard');
  });

  it('shows the server message and clears the password when the login is refused', async () => {
    await submit('mc.rossi', 'wrong-password');
    answerLogin(401, {
      status: 401,
      code: 'INVALID_CREDENTIALS',
      detail: 'Invalid username or password.',
    });
    await fixture.whenStable();

    expect(el().querySelector('[role="alert"]')?.textContent).toContain(
      'Invalid username or password.',
    );
    expect(input('password').value).toBe('');
    expect(input('username').value).toBe('mc.rossi');
    expect(navigate).not.toHaveBeenCalled();
  });
});
