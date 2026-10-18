import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';
import { Title } from '@angular/platform-browser';
import { Router, TitleStrategy, provideRouter, withComponentInputBinding } from '@angular/router';
import { RouterTestingHarness } from '@angular/router/testing';

import { App } from './app';
import { routes } from './app.routes';
import { AetherTitleStrategy } from './core/navigation/aether-title-strategy';
import { DOMAINS } from './core/navigation/domains';
import { ANONYMOUS } from './core/auth/auth.service';
import { TEST_CONFIG, provideTestConfig, signIn } from './testing/test-config';

/** Domains whose landing route is a real screen instead of the placeholder named after the domain. */
const LANDING_PAGES: Partial<Record<string, string>> = { colonies: 'Bases', fleet: 'Fleet' };

describe('App routing', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        provideRouter(routes, withComponentInputBinding()),
        provideHttpClient(),
        provideHttpClientTesting(),
        provideTestConfig(),
        { provide: TitleStrategy, useClass: AetherTitleStrategy },
      ],
    });
  });

  describe('when signed in', () => {
    beforeEach(() => signIn());

    it('redirects the root URL to Mission Control', async () => {
      const harness = await RouterTestingHarness.create('/');

      expect(harness.routeNativeElement?.querySelector('h1')?.textContent).toBe('Mission Control');
      expect(TestBed.inject(Title).getTitle()).toBe('Mission Control · AETHER');
    });

    it.each(DOMAINS.map((d) => [d.path, LANDING_PAGES[d.path] ?? d.label]))(
      'lazy-loads the %s feature',
      async (path, heading) => {
        const harness = await RouterTestingHarness.create(`/${path}`);

        expect(harness.routeNativeElement?.querySelector('h1')?.textContent).toBe(heading);
        expect(TestBed.inject(Title).getTitle()).toBe(`${heading} · AETHER`);
      },
    );

    it('shows a not-found page for unknown URLs', async () => {
      const harness = await RouterTestingHarness.create('/does-not-exist');

      expect(harness.routeNativeElement?.querySelector('h1')?.textContent).toBe('Page not found');
    });

    it('renders the shell with a link per domain and the backend status', async () => {
      const fixture = TestBed.createComponent(App);
      await fixture.whenStable();
      TestBed.inject(HttpTestingController)
        .expectOne(TEST_CONFIG.healthUrl)
        .flush({ status: 'UP' });
      await fixture.whenStable();
      const el = fixture.nativeElement as HTMLElement;

      const links = Array.from(el.querySelectorAll('nav a')).map((a) => a.getAttribute('href'));
      expect(links).toEqual(['/dashboard', ...DOMAINS.map((d) => `/${d.path}`)]);
      expect(el.querySelector('a.skip-link')?.getAttribute('href')).toBe('#main-content');
      expect(el.textContent).toContain('Backend online');
      expect(el.textContent).toContain('Signed in as Laura Rossi');
    });
    it('signs out from the header and shows the login page', async () => {
      const fixture = TestBed.createComponent(App);
      const http = TestBed.inject(HttpTestingController);
      await fixture.whenStable();
      http.expectOne(TEST_CONFIG.healthUrl).flush({ status: 'UP' });
      await fixture.whenStable();
      const el = fixture.nativeElement as HTMLElement;

      Array.from(el.querySelectorAll('button'))
        .find((b) => b.textContent?.trim() === 'Sign out')!
        .click();
      http
        .expectOne(`${TEST_CONFIG.apiBaseUrl}/auth/logout`)
        .flush(null, { status: 204, statusText: 'No Content' });
      await fixture.whenStable();

      expect(TestBed.inject(Router).url).toBe('/login');
      expect(el.querySelector('nav')).toBeNull();
    });
  });

  describe('when nobody is signed in', () => {
    beforeEach(() => signIn(ANONYMOUS));

    it.each(['/dashboard', '/missions', '/colonies/crew'])(
      'sends a visitor of %s to the login page and back afterwards',
      async (url) => {
        const harness = await RouterTestingHarness.create(url);

        expect(harness.routeNativeElement?.querySelector('h1')?.textContent).toBe('Sign in');
        expect(TestBed.inject(Router).url).toBe(`/login?returnUrl=${encodeURIComponent(url)}`);
      },
    );

    it('shows neither the navigation nor a user', async () => {
      const fixture = TestBed.createComponent(App);
      await fixture.whenStable();
      TestBed.inject(HttpTestingController)
        .expectOne(TEST_CONFIG.healthUrl)
        .flush({ status: 'UP' });
      await fixture.whenStable();
      const el = fixture.nativeElement as HTMLElement;

      expect(el.querySelector('nav')).toBeNull();
      expect(el.textContent).not.toContain('Signed in');
    });
  });
});
