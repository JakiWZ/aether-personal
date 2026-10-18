import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';

import { TEST_CONFIG, pageOf, provideTestConfig } from '../../../testing/test-config';
import { Vehicle, VehicleService } from './vehicle.service';

const URL = `${TEST_CONFIG.apiBaseUrl}/vehicles`;

describe('VehicleService', () => {
  let service: VehicleService;
  let http: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting(), provideTestConfig()],
    });
    service = TestBed.inject(VehicleService);
    http = TestBed.inject(HttpTestingController);
  });

  afterEach(() => http.verify());

  it('gets the first page of vehicles from the configured API URL', () => {
    const vehicles: Vehicle[] = [];
    service.list().subscribe((page) => vehicles.push(...page.items));

    const req = http.expectOne((r) => r.url === URL);
    expect(req.request.method).toBe('GET');
    expect(req.request.params.has('status')).toBe(false);
    expect(req.request.params.get('page')).toBe('0');
    expect(req.request.params.get('size')).toBe('20');
    req.flush(
      pageOf([
        {
          code: 'ROV-ARS-01',
          typeCode: 'ROVER',
          typeName: 'Pressurised rover',
          manufacturer: null,
          model: null,
          serialNumber: null,
          status: 'IN_USE',
          criticality: 'HIGH',
          colonyCode: 'ARS-01',
          active: true,
          commissionedAt: null,
          operatingHours: 0,
        },
      ]),
    );

    expect(vehicles.map((v) => v.code)).toEqual(['ROV-ARS-01']);
  });

  it('sends the status filter when given', () => {
    service.list('OUT_OF_SERVICE', 2).subscribe();

    const req = http.expectOne((r) => r.url === URL);
    expect(req.request.params.get('status')).toBe('OUT_OF_SERVICE');
    expect(req.request.params.get('page')).toBe('2');
    req.flush(pageOf([]));
  });
});
