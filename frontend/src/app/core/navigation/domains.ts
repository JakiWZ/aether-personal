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
    label: 'Colonies & Crew',
    squad: 'ARES',
    summary: 'Bases, habitats, crew members, skills and certifications.',
  },
  {
    path: 'missions',
    label: 'Missions',
    squad: 'PHOENIX',
    summary: 'Mission planning, crew assignment and lifecycle.',
  },
  {
    path: 'fleet',
    label: 'Fleet & Maintenance',
    squad: 'TITAN',
    summary: 'Rovers and vehicles, availability and maintenance work.',
  },
  {
    path: 'inventory',
    label: 'Resources & Logistics',
    squad: 'ORION',
    summary: 'Stock levels, movements, thresholds and transfers between bases.',
  },
  {
    path: 'incidents',
    label: 'Incidents & Safety',
    squad: 'HELIOS',
    summary: 'Incident reporting and handling, responders and timeline.',
  },
];

/** Looks up a domain by path; throws on a typo so a broken route fails fast in tests. */
export function domainByPath(path: string): DomainLink {
  const domain = DOMAINS.find((d) => d.path === path);
  if (!domain) {
    throw new Error(`Unknown domain: ${path}`);
  }
  return domain;
}
