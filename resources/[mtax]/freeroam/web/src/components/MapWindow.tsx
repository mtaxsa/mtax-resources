import React, { useCallback, useEffect, useRef, useState } from 'react';
import { usePoll } from '../hooks/usePoll';
import { useI18n } from '../i18n';
import { fetchNui } from '../utils/fetchNui';
import { useFreeroam } from './context';
import { clamp } from '../utils/misc';
import type { ToolProps } from './tools';
import { asArray, type Blip } from './types';
import { Button, Input } from './ui';

const WORLD = 6000;
const HALF = WORLD / 2;
const MAX_ZOOM = 4;
const DRAG_THRESHOLD = 3;

interface View {
  zoom: number;
  cx: number;
  cy: number;
  centred: boolean;
}

interface Target {
  x: number;
  y: number;
  z: number;
}

// Kept between openings, like the rest of the session memory.
let savedView: View = { zoom: 1, cx: 0, cy: 0, centred: false };
let savedTarget: Target | null = null;

const clampView = (view: View): View => {
  const half = WORLD / view.zoom / 2;
  return {
    ...view,
    cx: clamp(view.cx, -HALF + half, HALF - half),
    cy: clamp(view.cy, -HALF + half, HALF - half),
  };
};

export const MapWindow: React.FC<ToolProps> = () => {
  const { t } = useI18n();
  const { close } = useFreeroam();

  const [view, setView] = useState<View>(savedView);
  const [target, setTarget] = useState<Target | null>(savedTarget);
  const [inputs, setInputs] = useState(() => ({
    x: savedTarget?.x.toFixed(2) ?? '',
    y: savedTarget?.y.toFixed(2) ?? '',
    z: savedTarget?.z.toFixed(2) ?? '',
  }));
  const [size, setSize] = useState({ w: 1, h: 1 });
  const [hover, setHover] = useState<Blip | null>(null);

  const wrapRef = useRef<HTMLDivElement>(null);

  const reply = usePoll<{ blips?: Blip[]; dead?: boolean }>('blips', 250, {
    blips: [
      { x: 2488, y: -1666, key: 'me', name: 'You', me: true },
      { x: -2026, y: 156, key: 'Maria', name: 'Maria Cortez', me: false },
    ],
    dead: false,
  });

  const blips = asArray<Blip>(reply?.blips);
  const dead = reply?.dead === true;

  useEffect(() => {
    savedView = view;
  }, [view]);

  useEffect(() => {
    const node = wrapRef.current;
    if (!node) return;

    const observer = new ResizeObserver(() => setSize({ w: node.clientWidth || 1, h: node.clientHeight || 1 }));
    observer.observe(node);
    return () => observer.disconnect();
  }, []);

  // First open centres on the player.
  useEffect(() => {
    if (view.centred) return;
    const me = blips.find((blip) => blip.me);
    if (me) setView((current) => clampView({ ...current, cx: me.x, cy: me.y, centred: true }));
  }, [blips, view.centred]);

  const toScreen = useCallback(
    (wx: number, wy: number) => [
      ((wx - view.cx) / WORLD) * view.zoom * size.w + size.w / 2,
      ((view.cy - wy) / WORLD) * view.zoom * size.h + size.h / 2,
    ],
    [view, size]
  );

  const toWorld = useCallback(
    (sx: number, sy: number, at: View = view) => [
      at.cx + ((sx - size.w / 2) * WORLD) / (at.zoom * size.w),
      at.cy - ((sy - size.h / 2) * WORLD) / (at.zoom * size.h),
    ],
    [view, size]
  );

  const pickTarget = useCallback((wx: number, wy: number) => {
    fetchNui<{ z?: number }>('ground', { x: wx, y: wy }, { z: 3 }).then((result) => {
      const next = { x: wx, y: wy, z: Number(result?.z) || 3 };
      savedTarget = next;
      setTarget(next);
      setInputs({ x: next.x.toFixed(2), y: next.y.toFixed(2), z: next.z.toFixed(2) });
    });
  }, []);

  useEffect(() => {
    const node = wrapRef.current;
    if (!node) return;

    const onWheel = (event: WheelEvent) => {
      event.preventDefault();
      event.stopPropagation();

      const box = node.getBoundingClientRect();
      const mx = event.clientX - box.left;
      const my = event.clientY - box.top;

      setView((current) => {
        const [bx, by] = toWorld(mx, my, current);
        const zoom = clamp(current.zoom * (event.deltaY < 0 ? 1.25 : 0.8), 1, MAX_ZOOM);
        const [ax, ay] = toWorld(mx, my, { ...current, zoom });
        return clampView({ ...current, zoom, cx: current.cx + bx - ax, cy: current.cy + by - ay });
      });
    };

    node.addEventListener('wheel', onWheel, { passive: false });
    return () => node.removeEventListener('wheel', onWheel);
  }, [toWorld]);

  const onMouseDown = (event: React.MouseEvent<HTMLDivElement>) => {
    if (event.button !== 0 || (event.target as HTMLElement).dataset.blip) return;
    event.preventDefault();

    const box = event.currentTarget.getBoundingClientRect();
    const start = { x: event.clientX, y: event.clientY };
    let last = start;
    let moved = false;

    const move = (next: MouseEvent) => {
      if (Math.abs(next.clientX - start.x) + Math.abs(next.clientY - start.y) > DRAG_THRESHOLD) moved = true;

      if (moved) {
        const dx = next.clientX - last.x;
        const dy = next.clientY - last.y;
        setView((current) => {
          const span = WORLD / current.zoom;
          return clampView({ ...current, cx: current.cx - (dx / size.w) * span, cy: current.cy + (dy / size.h) * span });
        });
      }

      last = { x: next.clientX, y: next.clientY };
    };

    const up = () => {
      window.removeEventListener('mousemove', move);
      window.removeEventListener('mouseup', up);

      if (!moved) {
        const [wx, wy] = toWorld(start.x - box.left, start.y - box.top);
        pickTarget(wx, wy);
      }
    };

    window.addEventListener('mousemove', move);
    window.addEventListener('mouseup', up);
  };

  const teleport = () => {
    fetchNui<{ ok?: boolean }>('teleport', {
      x: parseFloat(inputs.x),
      y: parseFloat(inputs.y),
      z: parseFloat(inputs.z),
    }).then((result) => {
      if (result?.ok) close('map');
    });
  };

  const warp = (blip: Blip) => {
    fetchNui<{ ok?: boolean }>('warp', { key: blip.key }).then((result) => {
      if (result?.ok) close('map');
    });
  };

  const centreOnMe = () => {
    const me = blips.find((blip) => blip.me);
    if (me) setView((current) => clampView({ ...current, cx: me.x, cy: me.y }));
  };

  const [left, top] = toScreen(-HALF, HALF);
  const marker = target ? toScreen(target.x, target.y) : null;
  const hovered = hover ? toScreen(hover.x, hover.y) : null;

  return (
    <>
      <div
        ref={wrapRef}
        onMouseDown={onMouseDown}
        className="relative min-h-0 flex-1 cursor-crosshair overflow-hidden bg-[#0d1b24]"
      >
        <img
          src="./map.png"
          draggable={false}
          className="pointer-events-none absolute max-w-none select-none"
          style={{ left, top, width: size.w * view.zoom, height: size.h * view.zoom }}
        />

        {blips.map((blip) => {
          const [x, y] = toScreen(blip.x, blip.y);
          if (x < -8 || y < -8 || x > size.w + 8 || y > size.h + 8) return null;

          return (
            <div
              key={blip.key}
              data-blip="1"
              onMouseEnter={() => setHover(blip)}
              onMouseLeave={() => setHover(null)}
              onClick={() => !blip.me && warp(blip)}
              className={`absolute -translate-x-1/2 -translate-y-1/2 rounded-full border-2 border-white shadow-[0_0_0_2px_rgb(0_0_0/0.4)] ${
                blip.me ? 'h-3.5 w-3.5 bg-brand' : 'h-3 w-3 cursor-pointer bg-warn hover:scale-125'
              }`}
              style={{ left: x, top: y }}
            />
          );
        })}

        {marker && (
          <div
            className="pointer-events-none absolute h-5 w-5 -translate-x-1/2 -translate-y-1/2 rounded-full border-2 border-bad"
            style={{ left: marker[0], top: marker[1] }}
          >
            <span className="absolute top-1/2 left-1/2 h-1.5 w-1.5 -translate-x-1/2 -translate-y-1/2 rounded-full bg-bad" />
          </div>
        )}

        {hover && hovered && (
          <div
            className="pointer-events-none absolute -translate-x-1/2 -translate-y-full rounded-md bg-panel-solid px-2 py-1 text-[11px] font-semibold whitespace-nowrap text-ink shadow"
            style={{ left: hovered[0], top: hovered[1] - 9 }}
          >
            {hover.name}
          </div>
        )}

        <div className="pointer-events-none absolute top-2 left-2 rounded-md bg-black/60 px-2 py-1 text-[11px] text-ink-dim">
          {dead ? t('map.choose_respawn') : t('map.zoom_hint', { zoom: view.zoom.toFixed(1) })}
        </div>
      </div>

      <div className="flex shrink-0 items-center gap-2 border-t border-line px-3 py-2.5">
        {(['x', 'y', 'z'] as const).map((axis) => (
          <Input
            key={axis}
            data-field={axis}
            value={inputs[axis]}
            placeholder={axis.toUpperCase()}
            onChange={(event) => setInputs((current) => ({ ...current, [axis]: event.target.value.replace(/[^0-9.-]/g, '') }))}
            onKeyDown={(event) => event.key === 'Enter' && teleport()}
            className="w-[90px]"
          />
        ))}
        <Button onClick={centreOnMe}>{t('map.my_location')}</Button>
        <Button variant="primary" className="flex-1" onClick={teleport}>
          {dead ? t('map.respawn_here') : t('map.teleport')}
        </Button>
      </div>
    </>
  );
};
