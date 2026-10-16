import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';

import { TEST_CONFIG, provideTestConfig } from '../../../testing/test-config';
import { MissionService, NewMission } from './mission.service';

describe('MissionService', () => {
  let service: MissionService;
  let http: HttpTestingController;
  const url = `${TEST_CONFIG.apiBaseUrl}/missions`;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting(), provideTestConfig()],
    });
    service = TestBed.inject(MissionService);
    http = TestBed.inject(HttpTestingController);
  });

  afterEach(() => http.verify());

  it('lists missions from the configured API URL', () => {
    service.list().subscribe();

    const req = http.expectOne(url);
    expect(req.request.method).toBe('GET');
    req.flush([]);
  });

  it('posts a new mission', () => {
    const mission: NewMission = {
      code: 'PHX-020',
      title: 'Jezero delta survey',
      description: null,
      objective: 'Map the delta front',
      type: 'EXPLORATION',
      originColonyCode: 'ARS-01',
      plannedStartAt: '2099-05-01T08:00:00Z',
      plannedEndAt: '2099-05-03T18:00:00Z',
      priority: 'HIGH',
      safetyLevel: 'ELEVATED',
    };
    service.create(mission).subscribe();

    const req = http.expectOne(url);
    expect(req.request.method).toBe('POST');
    expect(req.request.body).toEqual(mission);
    req.flush({});
  });
});
