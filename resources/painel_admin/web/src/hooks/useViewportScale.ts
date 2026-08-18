import { useEffect, useState } from 'react';
import { ZOOM_BREAKPOINTS } from '../config/zoomConfig';

const lookupPercent = (width: number) =>
  (ZOOM_BREAKPOINTS.find((bp) => width <= bp.maxWidth) ?? ZOOM_BREAKPOINTS[ZOOM_BREAKPOINTS.length - 1]).percent;

/**
 * Scales a fixed-size (pixel-perfect) layout so it occupies a percentage of
 * the screen width, using the manual per-resolution table in
 * `config/zoomConfig.ts`, while still guaranteeing the layout never gets
 * cropped on a screen too short/narrow for the resulting scale.
 *
 * @param designWidth Width (px) the layout was designed at
 * @param designHeight Height (px) the layout was designed at
 * @param margin Minimum breathing room (px) to keep clear on each side
 * @param overridePercent When set (0-1), used instead of the breakpoint
 * table — lets the user pick their own zoom manually. `null`/`undefined`
 * falls back to the automatic per-resolution lookup.
 */
export const useViewportScale = (designWidth: number, designHeight: number, margin = 32, overridePercent?: number | null) => {
  const computeScale = () => {
    const percent = overridePercent ?? lookupPercent(window.innerWidth);
    const targetScale = (window.innerWidth * percent) / designWidth;
    const maxSafeScale = Math.min(
      (window.innerWidth - margin * 2) / designWidth,
      (window.innerHeight - margin * 2) / designHeight
    );

    return Math.min(targetScale, maxSafeScale);
  };

  const [scale, setScale] = useState(computeScale);

  useEffect(() => {
    const handleResize = () => setScale(computeScale());

    window.addEventListener('resize', handleResize);
    handleResize();

    return () => window.removeEventListener('resize', handleResize);
  }, [designWidth, designHeight, margin, overridePercent]);

  return scale;
};
