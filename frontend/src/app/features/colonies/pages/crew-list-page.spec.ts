import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';

import {
  SIGNED_IN,
  TEST_CONFIG,
  pageOf,
  provideTestConfig,
  signIn,
} from '../../../testing/test-config';
import { CrewMember } from '../data/crew-member.service';
import { CrewListPage } from './crew-list-page';

const URL = `${TEST_CONFIG.apiBaseUrl}/crew-members`;

const ROSSI: CrewMember = {
  employeeCode: 'CRW-001',
  firstName: 'Laura',
  lastName: 'Rossi',
  email: 'laura.rossi@aether.demo',
  operationalRole: 'Commander',
  status: 'ACTIVE',
  homeColonyCode: 'ARS-01',
};
const NOVAK: CrewMember = {
  employeeCode: 'CRW-002',
  firstName: 'Ivan',
  lastName: 'Novak',
  email: null,
  operationalRole: 'Engineer',
  status: 'MEDICAL_LEAVE',
  homeColonyCode: null,
};

describe('CrewListPage', () => {
  let fixture: ComponentFixture<CrewListPage>;
  let http: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        provideHttpClient(),
        provideHttpClientTesting(),
        provideRouter([]),
        provideTestConfig(),
      ],
    });
    http = TestBed.inject(HttpTestingController);
    fixture = TestBed.createComponent(CrewListPage);
  });

  afterEach(() => http.verify());

  const el = () => fixture.nativeElement as HTMLElement;
  const rows = () => Array.from(el().querySelectorAll('tbody tr'));

  async function respond(body: CrewMember[]): Promise<void> {
    http.expectOne((r) => r.url === URL).flush(pageOf(body));
    await fixture.whenStable();
  }

  it('shows a loading message until the crew arrives', async () => {
    await fixture.whenStable();

    expect(el().querySelector('[role="status"]')?.textContent).toContain('Loading crew');
    await respond([ROSSI]);
    expect(el().textContent).not.toContain('Loading crew');
  });

  it('lists code, name, role, status and base of every member', async () => {
    await respond([ROSSI, NOVAK]);

    expect(rows().map((r) => r.querySelector('.code')?.textContent)).toEqual([
      'CRW-001',
      'CRW-002',
    ]);
    expect(rows()[0].textContent).toContain('Laura Rossi');
    expect(rows()[0].textContent).toContain('Commander');
    expect(rows()[0].textContent).toContain('ARS-01');
    expect(rows()[1].querySelector('.badge')?.textContent?.trim()).toBe('Medical leave');
    expect(rows()[1].textContent).toContain('Unassigned');
  });

  it('shows an empty state when nobody is registered', async () => {
    await respond([]);

    expect(el().querySelector('table')).toBeNull();
    expect(el().querySelector('[role="status"]')?.textContent).toContain(
      'No crew members registered yet',
    );
  });

  it('confirms the member just registered', async () => {
    fixture.componentRef.setInput('created', 'CRW-002');
    await respond([ROSSI, NOVAK]);

    expect(el().querySelector('.success')?.textContent).toContain(
      'Crew member CRW-002 registered.',
    );
    expect(rows()[1].classList).toContain('highlight');
  });

  it('shows the server error and retries on demand', async () => {
    http
      .expectOne((r) => r.url === URL)
      .flush(
        { status: 503, code: 'SERVICE_UNAVAILABLE', detail: 'Database offline.' },
        { status: 503, statusText: 'Service Unavailable' },
      );
    await fixture.whenStable();

    const alert = el().querySelector('[role="alert"]');
    expect(alert?.textContent).toContain('Database offline.');

    alert!.querySelector('button')!.click();
    await respond([ROSSI]);

    expect(el().querySelector('[role="alert"]')).toBeNull();
    expect(rows()).toHaveLength(1);
  });

  it('offers "New crew member" only to users allowed to do it', async () => {
    const createLink = () =>
      Array.from(el().querySelectorAll('a')).find((a) => a.textContent === 'New crew member');
    signIn({ ...SIGNED_IN, permissions: SIGNED_IN.permissions.filter((p) => p !== 'CREW_MANAGE') });
    await respond([]);
    expect(createLink()).toBeUndefined();

    signIn();
    await fixture.whenStable();
    expect(createLink()?.getAttribute('href')).toBe('/new');
  });
});
