import { TestBed } from '@angular/core/testing';

import { pageOf } from '../../../testing/test-config';
import { Pager } from './pager';

describe('Pager', () => {
  async function render(page = pageOf(['a'], 0, 20, 1)) {
    const fixture = TestBed.createComponent(Pager);
    fixture.componentRef.setInput('page', page);
    fixture.componentRef.setInput('singular', 'base');
    fixture.componentRef.setInput('plural', 'bases');
    const emitted: number[] = [];
    fixture.componentInstance.pageChange.subscribe((index) => emitted.push(index));
    await fixture.whenStable();
    return { el: fixture.nativeElement as HTMLElement, emitted };
  }

  it('only shows the count when everything fits on one page', async () => {
    const { el } = await render();

    expect(el.textContent?.trim()).toBe('1 base');
    expect(el.querySelector('button')).toBeNull();
  });

  it('moves to the previous and next page, never past the ends', async () => {
    const { el, emitted } = await render(pageOf(['a'], 2, 10, 30));
    const [previous, next] = Array.from(el.querySelectorAll('button'));

    expect(el.textContent).toContain('page 3 of 3');
    expect(next.disabled).toBe(true);
    previous.click();
    expect(emitted).toEqual([1]);
  });
});
