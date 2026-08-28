import { useEffect } from 'react';
import type { RefObject } from 'react';

/**
 * Routes mouse-wheel scrolling of a scroll container through a manual JS
 * listener instead of Chromium's native scrollbar wheel path.
 *
 * Why: CEF's off-screen-rendering mode has a long-standing bug
 * (cef/cef#3567, cef/cef#2949, cef/cef#3849). After the user drags the
 * *native* scrollbar thumb, wheel events delivered via SendMouseWheelEvent
 * stop scrolling the element -- the scrollbar's internal drag state never
 * resets because OSR wheel events carry no native_event, so Chromium keeps
 * dropping the wheel while the thumb drag still works. Intercepting `wheel`
 * here and adjusting `scrollTop` ourselves sidesteps that path entirely. The
 * native thumb drag is a separate input path and keeps working, so the
 * visible scrollbar stays fully usable.
 */
export const useWheelScroll = (ref: RefObject<HTMLElement>) => {
  useEffect(() => {
    const el = ref.current;
    if (!el) return;

    const onWheel = (event: WheelEvent) => {
      event.preventDefault();
      // Stop the wheel event here so it doesn't bubble into an ancestor
      // scroll container (e.g. the tab body behind the resources list) and
      // scroll the background along with this box.
      event.stopPropagation();
      el.scrollTop += event.deltaY;
    };

    el.addEventListener('wheel', onWheel, { passive: false });
    return () => el.removeEventListener('wheel', onWheel);
  }, [ref]);
};