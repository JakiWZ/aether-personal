import { TestBed } from '@angular/core/testing';

import { FeaturePlaceholder } from './feature-placeholder';

describe('FeaturePlaceholder', () => {
  it('renders the domain it is bound to', async () => {
    const fixture = TestBed.createComponent(FeaturePlaceholder);
    fixture.componentRef.setInput('domain', 'missions');
    await fixture.whenStable();

    const el = fixture.nativeElement as HTMLElement;
    expect(el.querySelector('h1')?.textContent).toBe('Missions');
    expect(el.textContent).toContain('Squad PHOENIX');
  });

  it('renders nothing for an unknown domain', async () => {
    const fixture = TestBed.createComponent(FeaturePlaceholder);
    fixture.componentRef.setInput('domain', 'unknown');
    await fixture.whenStable();

    expect((fixture.nativeElement as HTMLElement).querySelector('h1')).toBeNull();
  });
});
