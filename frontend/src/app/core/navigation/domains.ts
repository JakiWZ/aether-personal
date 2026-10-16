/** Business domains of AETHER, in navigation order. Paths match the lazy routes in app.routes.ts. */
export interface DomainLink {
  readonly path: string;
  readonly label: string;
  readonly squad: string;
  readonly summary: string;
}

export const DOMAINS: readonly DomainLink[] = [
  {
    path: 'colonies',
    label: 'Colonie ed equipaggio',
    squad: 'ARES',
    summary: 'Basi, habitat, membri dell’equipaggio, competenze e certificazioni.',
  },
  {
    path: 'missions',
    label: 'Missioni',
    squad: 'PHOENIX',
    summary: 'Pianificazione delle missioni, assegnazione dell’equipaggio e ciclo di vita.',
  },
  {
    path: 'fleet',
    label: 'Flotta e manutenzione',
    squad: 'TITAN',
    summary: 'Rover e veicoli, disponibilità e interventi di manutenzione.',
  },
  {
    path: 'inventory',
    label: 'Risorse e logistica',
    squad: 'ORION',
    summary: 'Scorte, movimenti di magazzino, soglie e trasferimenti tra basi.',
  },
  {
    path: 'incidents',
    label: 'Incidenti e sicurezza',
    squad: 'HELIOS',
    summary: 'Segnalazione e gestione degli incidenti, soccorritori e timeline.',
  },
];
