import { HttpErrorResponse } from '@angular/common/http';

/** One invalid field of a `VALIDATION_FAILED` response (ADR-0005). */
export interface FieldViolation {
  readonly field: string;
  readonly message: string;
}

/** RFC 9457 Problem Details as produced by the backend `GlobalExceptionHandler` (ADR-0005). */
export interface ProblemDetail {
  readonly type?: string;
  readonly title?: string;
  readonly status: number;
  readonly detail?: string;
  readonly instance?: string;
  readonly code: string;
  readonly errors?: readonly FieldViolation[];
}

/** Error shape the UI works with, whatever went wrong. Switch on `code`, display `message`. */
export interface ApiError {
  /** HTTP status, or 0 when the server could not be reached. */
  readonly status: number;
  /** Stable backend code (e.g. `CREW_ASSIGNMENT_OVERLAP`) or one of the client codes below. */
  readonly code: string;
  readonly message: string;
  readonly fieldErrors: readonly FieldViolation[];
}

/** Codes produced by the client when the response is not a Problem Details document. */
export const ClientErrorCode = {
  NETWORK_ERROR: 'NETWORK_ERROR',
  UNEXPECTED_RESPONSE: 'UNEXPECTED_RESPONSE',
  UNKNOWN_ERROR: 'UNKNOWN_ERROR',
} as const;

const NETWORK_MESSAGE = 'Impossibile contattare il server. Verifica la connessione e riprova.';
const GENERIC_MESSAGE = 'Si è verificato un errore imprevisto. Riprova più tardi.';

export function isProblemDetail(body: unknown): body is ProblemDetail {
  if (typeof body !== 'object' || body === null) {
    return false;
  }
  const candidate = body as Record<string, unknown>;
  return typeof candidate['status'] === 'number' && typeof candidate['code'] === 'string';
}

/** Normalises anything thrown by HttpClient into an {@link ApiError}. */
export function toApiError(error: unknown): ApiError {
  if (!(error instanceof HttpErrorResponse)) {
    return {
      status: 0,
      code: ClientErrorCode.UNKNOWN_ERROR,
      message: GENERIC_MESSAGE,
      fieldErrors: [],
    };
  }
  if (error.status === 0) {
    return {
      status: 0,
      code: ClientErrorCode.NETWORK_ERROR,
      message: NETWORK_MESSAGE,
      fieldErrors: [],
    };
  }
  const body: unknown = error.error;
  if (isProblemDetail(body)) {
    return {
      status: body.status,
      code: body.code,
      message: body.detail ?? body.title ?? GENERIC_MESSAGE,
      fieldErrors: body.errors ?? [],
    };
  }
  return {
    status: error.status,
    code: ClientErrorCode.UNEXPECTED_RESPONSE,
    message: GENERIC_MESSAGE,
    fieldErrors: [],
  };
}
