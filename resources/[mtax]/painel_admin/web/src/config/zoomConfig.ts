/**
 * Manual panel width per resolution range, expressed as a percentage (0-1)
 * of the screen width, so the panel's size can be tuned by eye instead of
 * relying purely on a formula.
 *
 * Ordered by `maxWidth` ascending. The first entry whose `maxWidth` is >=
 * the screen width is used. Edit the `percent` values freely; add/remove
 * rows to add more breakpoints. The last row (maxWidth: Infinity) is the
 * catch-all for anything wider than the rows above it.
 */
export interface ZoomBreakpoint {
  maxWidth: number;
  percent: number;
}

export const ZOOM_BREAKPOINTS: ZoomBreakpoint[] = [
  { maxWidth: 1280, percent: 0.65 },
  { maxWidth: 1366, percent: 0.62 },
  { maxWidth: 1600, percent: 0.65 },
  { maxWidth: 1920, percent: 0.50 },
  { maxWidth: 2560, percent: 0.55 },
  { maxWidth: Infinity, percent: 0.45 },
];

export const MANUAL_ZOOM_OPTIONS = [0.4, 0.45, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.9, 1];
export const ZOOM_OVERRIDE_STORAGE_KEY = 'mtax-admin-zoom-override';
