import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { Component } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { Router, provideRouter } from '@angular/router';
import { RouterTestingHarness } from '@angular/router/testing';

import { SIGNED_IN, provideTestConfig, signIn } from '../../testing/test-config';
import { authGuard, permissionGuard, safeReturnUrl } from './auth.guard';
import { ANONYMOUS } from './auth.service';

@Component({ template: '<h1>Page</h1>' })
class Page {}

describe('auth guards', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        provideHttpClient(),
        provideHttpClientTesting(),
        provideTestConfig(),
        provideRouter([
          { path: 'login', component: Page },
          { path: 'missions', canMatch: [authGuard], component: Page },
          {
            path: 'missions/new',
            canMatch: [authGuard, permissionGuard('MISSION_MANAGE', '/missions')],
            component: Page,
          },
        ]),
      ],
    });
  });

  it('lets a signed-in user through', async () => {
    signIn();
    await RouterTestingHarness.create('/missions');

    expect(TestBed.inject(Router).url).toBe('/missions');
  });

  it('sends an anonymous visitor to the login page with the way back', async () => {
    signIn(ANONYMOUS);
    await RouterTestingHarness.create('/missions/new');

    expect(TestBed.inject(Router).url).toBe('/login?returnUrl=%2Fmissions%2Fnew');
  });

  it('sends a user without the permission back to the list', async () => {
    signIn({ ...SIGNED_IN, permissions: ['MISSION_READ'] });
    await RouterTestingHarness.create('/missions/new');

    expect(TestBed.inject(Router).url).toBe('/missions');
  });
});

describe('safeReturnUrl', () => {
  it.each([
    ['/missions?page=2', '/missions?page=2'],
    [undefined, '/dashboard'],
    ['', '/dashboard'],
    ['https://evil.example', '/dashboard'],
    ['//evil.example/path', '/dashboard'],
    ['/\\evil.example', '/dashboard'],
    ['javascript:alert(1)', '/dashboard'],
    ['/login?returnUrl=/x', '/dashboard'],
  ])('turns %s into %s', (candidate, expected) => {
    expect(safeReturnUrl(candidate)).toBe(expected);
  });
});
