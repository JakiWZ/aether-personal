import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';
import { Title } from '@angular/platform-browser';
import { TitleStrategy, provideRouter, withComponentInputBinding } from '@angular/router';
import { RouterTestingHarness } from '@angular/router/testing';

import { App } from './app';
import { routes } from './app.routes';
import { AetherTitleStrategy } from './core/navigation/aether-title-strategy';
import { DOMAINS } from './core/navigation/domains';
import { TEST_CONFIG, provideTestConfig } from './testing/test-config';

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

  it('redirects the root URL to Mission Control', async () => {
    const harness = await RouterTestingHarness.create('/');

    expect(harness.routeNativeElement?.querySelector('h1')?.textContent).toBe('Mission Control');
    expect(TestBed.inject(Title).getTitle()).toBe('Mission Control · AETHER');
  });

  it.each(DOMAINS.map((d) => [d.path, d.label]))(
    'lazy-loads the %s feature',
    async (path, label) => {
      const harness = await RouterTestingHarness.create(`/${path}`);

      expect(harness.routeNativeElement?.querySelector('h1')?.textContent).toBe(label);
      expect(TestBed.inject(Title).getTitle()).toBe(`${label} · AETHER`);
    },
  );

  it('shows a not-found page for unknown URLs', async () => {
    const harness = await RouterTestingHarness.create('/does-not-exist');

    expect(harness.routeNativeElement?.querySelector('h1')?.textContent).toBe('Pagina non trovata');
  });

  it('renders the shell with a link per domain and the backend status', async () => {
    const fixture = TestBed.createComponent(App);
    await fixture.whenStable();
    TestBed.inject(HttpTestingController).expectOne(TEST_CONFIG.healthUrl).flush({ status: 'UP' });
    await fixture.whenStable();
    const el = fixture.nativeElement as HTMLElement;

    const links = Array.from(el.querySelectorAll('nav a')).map((a) => a.getAttribute('href'));
    expect(links).toEqual(['/dashboard', ...DOMAINS.map((d) => `/${d.path}`)]);
    expect(el.querySelector('a.skip-link')?.getAttribute('href')).toBe('#main-content');
    expect(el.textContent).toContain('Backend operativo');
  });
});
