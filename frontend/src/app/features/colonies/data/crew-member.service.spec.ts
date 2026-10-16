import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';

import { TEST_CONFIG, pageOf, provideTestConfig } from '../../../testing/test-config';
import { CrewMemberService, NewCrewMember } from './crew-member.service';

describe('CrewMemberService', () => {
  let service: CrewMemberService;
  let http: HttpTestingController;
  const url = `${TEST_CONFIG.apiBaseUrl}/crew-members`;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting(), provideTestConfig()],
    });
    service = TestBed.inject(CrewMemberService);
    http = TestBed.inject(HttpTestingController);
  });

  afterEach(() => http.verify());

  it('asks the configured API URL for the first page of crew members by default', () => {
    service.list().subscribe();

    const req = http.expectOne((r) => r.url === url);
    expect(req.request.method).toBe('GET');
    expect(req.request.params.get('page')).toBe('0');
    expect(req.request.params.get('size')).toBe('20');
    req.flush(pageOf([]));
  });

  it('asks for the requested page', () => {
    service.list(3, 50).subscribe();

    const req = http.expectOne((r) => r.url === url);
    expect(req.request.params.get('page')).toBe('3');
    expect(req.request.params.get('size')).toBe('50');
    req.flush(pageOf([], 3, 50));
  });

  it('posts a new crew member', () => {
    const member: NewCrewMember = {
      employeeCode: 'CRW-020',
      firstName: 'Anna',
      lastName: 'Verdi',
      email: null,
      operationalRole: 'Geologist',
      status: 'ACTIVE',
      homeColonyCode: 'ARS-01',
    };
    service.create(member).subscribe();

    const req = http.expectOne(url);
    expect(req.request.method).toBe('POST');
    expect(req.request.body).toEqual(member);
    req.flush(member);
  });
});
