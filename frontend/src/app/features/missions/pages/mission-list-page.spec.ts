import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';

import { TEST_CONFIG, provideTestConfig } from '../../../testing/test-config';
import { Mission } from '../data/mission.service';
import { MissionListPage } from './mission-list-page';

const URL = `${TEST_CONFIG.apiBaseUrl}/missions`;

const SURVEY: Mission = {
  code: 'PHX-001',
  title: 'Acidalia ridge survey',
  description: null,
  objectives: ['Survey the ridge'],
  type: 'EXPLORATION',
  originColonyCode: 'ARS-01',
  plannedStartAt: '2040-05-01T08:00:00Z',
  plannedEndAt: '2040-05-03T18:30:00+02:00',
  status: 'APPROVAL_PENDING',
  priority: 'HIGH',
  safetyLevel: 'HIGH_RISK',
  createdBy: 'system',
  createdAt: '2040-04-01T08:00:00Z',
};
const DRAFT: Mission = { ...SURVEY, code: 'PHX-020', title: 'Jezero', status: 'DRAFT' };

describe('MissionListPage', () => {
  let fixture: ComponentFixture<MissionListPage>;
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
    fixture = TestBed.createComponent(MissionListPage);
  });

  afterEach(() => http.verify());

  const el = () => fixture.nativeElement as HTMLElement;
  const rows = () => Array.from(el().querySelectorAll('tbody tr'));

  async function respond(body: Mission[]): Promise<void> {
    http.expectOne(URL).flush(body);
    await fixture.whenStable();
  }

  it('shows a loading message until the missions arrive', async () => {
    await fixture.whenStable();

    expect(el().querySelector('[role="status"]')?.textContent).toContain('Loading missions');
    await respond([SURVEY]);
    expect(el().textContent).not.toContain('Loading missions');
  });

  it('lists every mission with labels and its window in UTC', async () => {
    await respond([SURVEY]);

    const row = rows()[0];
    expect(row.querySelector('.code')?.textContent).toBe('PHX-001');
    expect(row.textContent).toContain('Exploration');
    expect(row.textContent).toContain('High risk');
    expect(row.querySelector('.status')?.textContent?.trim()).toBe('Approval pending');
    expect(row.querySelector('.window')?.textContent?.replace(/\s+/g, ' ').trim()).toBe(
      '2040-05-01 08:00 to 2040-05-03 16:30',
    );
  });

  it('shows an empty state when no mission exists', async () => {
    await respond([]);

    expect(el().querySelector('table')).toBeNull();
    expect(el().querySelector('[role="status"]')?.textContent).toContain('No missions planned yet');
  });

  it('confirms the mission just drafted', async () => {
    fixture.componentRef.setInput('created', 'PHX-020');
    await respond([SURVEY, DRAFT]);

    expect(el().querySelector('.success')?.textContent).toContain('Mission PHX-020 drafted.');
    expect(rows()[1].classList).toContain('highlight');
    expect(rows()[1].querySelector('.status')?.textContent?.trim()).toBe('Draft');
  });

  it('shows the server error and retries on demand', async () => {
    http
      .expectOne(URL)
      .flush(
        { status: 503, code: 'SERVICE_UNAVAILABLE', detail: 'Database offline.' },
        { status: 503, statusText: 'Service Unavailable' },
      );
    await fixture.whenStable();

    const alert = el().querySelector('[role="alert"]');
    expect(alert?.textContent).toContain('Database offline.');

    alert!.querySelector('button')!.click();
    await respond([SURVEY]);

    expect(el().querySelector('[role="alert"]')).toBeNull();
    expect(rows()).toHaveLength(1);
  });
});
