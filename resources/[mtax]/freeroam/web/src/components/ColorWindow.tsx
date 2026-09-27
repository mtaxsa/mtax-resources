import React, { useCallback, useEffect, useRef, useState } from 'react';
import { useI18n } from '../i18n';
import { fetchNui } from '../utils/fetchNui';
import { clamp } from '../utils/misc';
import type { ToolProps } from './tools';
import { Button, Input, SectionLabel } from './ui';

type Rgb = [number, number, number];
type Hsv = [number, number, number];

const PRESETS: Rgb[] = [
  [255, 255, 255], [200, 200, 200], [0, 0, 0], [255, 77, 141], [255, 154, 90],
  [245, 197, 24], [34, 197, 94], [56, 211, 227], [59, 130, 246], [168, 85, 247],
];

const SLOTS = [1, 2, 3, 4, 5];
const SEND_INTERVAL = 120;

const hsvToRgb = ([h, s, v]: Hsv): Rgb => {
  const hue = ((h % 360) + 360) % 360;
  const c = v * s;
  const x = c * (1 - Math.abs(((hue / 60) % 2) - 1));
  const m = v - c;
  const [r, g, b] =
    hue < 60 ? [c, x, 0] : hue < 120 ? [x, c, 0] : hue < 180 ? [0, c, x] : hue < 240 ? [0, x, c] : hue < 300 ? [x, 0, c] : [c, 0, x];
  return [Math.round((r + m) * 255), Math.round((g + m) * 255), Math.round((b + m) * 255)];
};

const rgbToHsv = ([r, g, b]: Rgb): Hsv => {
  const [rr, gg, bb] = [r / 255, g / 255, b / 255];
  const high = Math.max(rr, gg, bb);
  const delta = high - Math.min(rr, gg, bb);
  let h = 0;

  if (delta > 0) {
    if (high === rr) h = ((gg - bb) / delta) % 6;
    else if (high === gg) h = (bb - rr) / delta + 2;
    else h = (rr - gg) / delta + 4;
    h *= 60;
  }

  return [(h + 360) % 360, high > 0 ? delta / high : 0, high];
};

const css = (rgb: Rgb) => `rgb(${rgb.join(' ')})`;

let savedHsv: Hsv = [340, 0.7, 1];
let savedSlot = 1;

export const ColorWindow: React.FC<ToolProps> = () => {
  const { t } = useI18n();
  const [hsv, setHsv] = useState<Hsv>(savedHsv);
  const [slot, setSlot] = useState(savedSlot);
  const lastSent = useRef(0);

  const rgb = hsvToRgb(hsv);
  const [inputs, setInputs] = useState(() => rgb.map(String));

  useEffect(() => {
    savedHsv = hsv;
    savedSlot = slot;
  }, [hsv, slot]);

  const send = useCallback((color: Rgb, force: boolean) => {
    const now = Date.now();
    if (!force && now - lastSent.current < SEND_INTERVAL) return;
    lastSent.current = now;
    fetchNui('color', { slot: savedSlot, r: color[0], g: color[1], b: color[2] });
  }, []);

  // Keeps hue and saturation when the new colour is grey or black, so the picker does not jump.
  const fromRgb = useCallback((color: Rgb, push: boolean) => {
    setHsv((current) => {
      const next = rgbToHsv(color);
      return [next[1] > 0.001 ? next[0] : current[0], next[2] > 0.001 ? next[1] : current[1], next[2]];
    });
    setInputs(color.map(String));
    if (push) send(color, true);
  }, [send]);

  const loadSlot = useCallback((index: number) => {
    savedSlot = index;
    setSlot(index);
    fetchNui<{ rgb?: Rgb | false }>('colorGet', { slot: index }).then((reply) => {
      if (Array.isArray(reply?.rgb)) fromRgb(reply.rgb as Rgb, false);
    });
  }, [fromRgb]);

  useEffect(() => {
    loadSlot(savedSlot);
  }, [loadSlot]);

  const drag = (apply: (u: number, v: number) => Hsv) => (event: React.MouseEvent<HTMLDivElement>) => {
    event.preventDefault();
    const box = event.currentTarget.getBoundingClientRect();

    const update = (x: number, y: number, force: boolean) => {
      const next = apply(clamp((x - box.left) / box.width, 0, 1), clamp((y - box.top) / box.height, 0, 1));
      const color = hsvToRgb(next);
      setHsv(next);
      setInputs(color.map(String));
      send(color, force);
    };

    const move = (next: MouseEvent) => update(next.clientX, next.clientY, false);
    const up = (next: MouseEvent) => {
      window.removeEventListener('mousemove', move);
      window.removeEventListener('mouseup', up);
      update(next.clientX, next.clientY, true);
    };

    window.addEventListener('mousemove', move);
    window.addEventListener('mouseup', up);
    update(event.clientX, event.clientY, false);
  };

  return (
    <div className="flex flex-col gap-3 px-3.5 py-3">
      <div>
        <SectionLabel>{t('color.apply_where')}</SectionLabel>
        <div className="grid grid-cols-[1fr_1fr_1fr_1fr_1.8fr] gap-1.5">
          {SLOTS.map((index) => (
            <Button key={index} active={slot === index} onClick={() => loadSlot(index)} className="px-1">
              {index === 5 ? t('color.headlight') : index}
            </Button>
          ))}
        </div>
      </div>

      <div>
        <SectionLabel>{t('color.tone')}</SectionLabel>
        <div
          onMouseDown={drag((u, v) => [hsv[0], u, 1 - v])}
          className="relative h-40 cursor-crosshair rounded-lg"
          style={{
            background: `linear-gradient(to top, #000, transparent), linear-gradient(to right, #fff, ${css(hsvToRgb([hsv[0], 1, 1]))})`,
          }}
        >
          <span
            className="pointer-events-none absolute h-3.5 w-3.5 -translate-x-1/2 -translate-y-1/2 rounded-full border-2 border-white shadow"
            style={{ left: `${hsv[1] * 100}%`, top: `${(1 - hsv[2]) * 100}%` }}
          />
        </div>
        <div
          onMouseDown={drag((u) => [u * 360, hsv[1], hsv[2]])}
          className="relative mt-2.5 h-3 cursor-pointer rounded-full"
          style={{ background: 'linear-gradient(to right, #f00, #ff0, #0f0, #0ff, #00f, #f0f, #f00)' }}
        >
          <span
            className="pointer-events-none absolute top-1/2 h-4 w-4 -translate-x-1/2 -translate-y-1/2 rounded-full border-2 border-white shadow"
            style={{ left: `${(hsv[0] / 360) * 100}%` }}
          />
        </div>
      </div>

      <div className="grid grid-cols-10 gap-1.5">
        {PRESETS.map((color) => (
          <button
            key={color.join()}
            title={color.join(', ')}
            onClick={() => fromRgb(color, true)}
            className="aspect-square rounded-md border border-line outline-none hover:scale-110"
            style={{ background: css(color) }}
          />
        ))}
      </div>

      <div>
        <SectionLabel>{t('color.exact_value')}</SectionLabel>
        <div className="grid grid-cols-3 gap-1.5">
          {['R', 'G', 'B'].map((label, index) => (
            <Input
              key={label}
              data-field={label}
              value={inputs[index]}
              maxLength={3}
              placeholder={label}
              onChange={(event) => {
                const next = [...inputs];
                next[index] = event.target.value.replace(/[^0-9]/g, '');
                setInputs(next);
                const color = next.map((value) => clamp(parseInt(value, 10) || 0, 0, 255)) as Rgb;
                setHsv(rgbToHsv(color));
              }}
              className="w-full"
            />
          ))}
        </div>
      </div>

      <div className="flex items-center gap-2">
        <div className="h-8 w-14 shrink-0 rounded-md border border-line" style={{ background: css(rgb) }} />
        <Button variant="primary" className="flex-1" onClick={() => send(rgb, true)}>
          {t('action.apply_color')}
        </Button>
      </div>
    </div>
  );
};
