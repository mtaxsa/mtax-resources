import React from 'react';
import { Sticker } from './Sticker';
import type { ChatType, WorldLabel } from './types';

interface Props {
  labels: WorldLabel[];
  types: Record<string, ChatType>;
  colorOf: (kind: string) => string;
}

const SLOT = 52;

export const Labels: React.FC<Props> = ({ labels, types, colorOf }) => (
  <>
    {labels.map((label) => {
      const type = types[label.k];
      if (!type) return null;
      const color = colorOf(label.k);

      return (
        <div
          key={label.i}
          className="pointer-events-none absolute animate-[labelIn_0.16s_ease-out] will-change-transform"
          style={{
            left: label.x,
            top: label.y - label.o * SLOT * label.z,
            opacity: label.a,
            transform: `translate(-50%, -100%) scale(${label.z})`,
            transformOrigin: 'bottom center',
          }}
        >
          <div
            className="max-w-[300px] rounded-xl bg-panel px-2.5 py-1.5"
            style={{
              borderLeft: `3px solid ${color}`,
              boxShadow: '0 8px 24px rgb(0 0 0 / 0.45)',
            }}
          >
            <div className="flex items-center gap-1.5">
              <span
                className="rounded px-1 py-0.5 text-[9px] leading-none font-extrabold tracking-wide text-black"
                style={{ background: color }}
              >
                {type.label}
              </span>
              <span className="truncate text-[12px] font-semibold text-ink">{label.n}</span>
            </div>

            <div className="mt-1 flex items-end gap-1.5 text-[12px] leading-snug break-words text-ink">
              <span className="min-w-0 flex-1">{label.t}</span>
              {label.s && <Sticker id={label.s} size={34} className="shrink-0" />}
            </div>
          </div>
        </div>
      );
    })}
  </>
);
