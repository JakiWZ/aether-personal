import { HttpErrorResponse } from '@angular/common/http';

import { ClientErrorCode, toApiError } from './api-error';

describe('toApiError', () => {
  it('maps a Problem Details business conflict to its stable code and detail', () => {
    const error = new HttpErrorResponse({
      status: 409,
      error: {
        type: 'about:blank',
        title: 'Conflict',
        status: 409,
        detail: 'Crew member CRW-001 is already assigned to an overlapping mission.',
        instance: '/api/v1/missions/42/crew',
        code: 'CREW_ASSIGNMENT_OVERLAP',
      },
    });

    expect(toApiError(error)).toEqual({
      status: 409,
      code: 'CREW_ASSIGNMENT_OVERLAP',
      message: 'Crew member CRW-001 is already assigned to an overlapping mission.',
      fieldErrors: [],
    });
  });

  it('keeps field violations of a validation error', () => {
    const error = new HttpErrorResponse({
      status: 400,
      error: {
        title: 'Bad Request',
        status: 400,
        code: 'VALIDATION_FAILED',
        errors: [{ field: 'code', message: 'must not be blank' }],
      },
    });

    const apiError = toApiError(error);

    expect(apiError.code).toBe('VALIDATION_FAILED');
    expect(apiError.message).toBe('Bad Request');
    expect(apiError.fieldErrors).toEqual([{ field: 'code', message: 'must not be blank' }]);
  });

  it('reports a network error when the server cannot be reached', () => {
    const apiError = toApiError(new HttpErrorResponse({ status: 0 }));

    expect(apiError.code).toBe(ClientErrorCode.NETWORK_ERROR);
    expect(apiError.status).toBe(0);
  });

  it('does not trust a body that is not Problem Details', () => {
    const error = new HttpErrorResponse({ status: 502, error: '<html>Bad Gateway</html>' });

    const apiError = toApiError(error);

    expect(apiError.code).toBe(ClientErrorCode.UNEXPECTED_RESPONSE);
    expect(apiError.status).toBe(502);
    expect(apiError.message).not.toContain('<html>');
  });

  it('handles errors that are not HTTP errors', () => {
    expect(toApiError(new Error('boom')).code).toBe(ClientErrorCode.UNKNOWN_ERROR);
  });
});
