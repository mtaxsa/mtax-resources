import React from 'react';
import { Popover } from './Popover';
import type { ChatType, Corner, Settings } from './types';

interface Props {
  settings: Settings;
  types: Record<string, ChatType>;
  tabs: string[];
  timestamps: boolean;
  patch: (next: Partial<Settings>) => void;
  setColor: (kind: string, color: string | null) => void;
  onCorner: (corner: Corner) => void;
  onReset: () => void;
}

const Row: React.FC<{ label: string; children: React.ReactNode }> = ({ label, children }) => (
  <div className="flex items-center justify-between gap-3 py-1.5">
    <span className="text-[12px] text-ink-dim">{label}</span>
    {children}
  </div>
);

const Toggle: React.FC<{ on: boolean; onClick: () => void }> = ({ on, onClick }) => (
  <button
    onClick={onClick}
    className="relative h-[18px] w-8 shrink-0 rounded-full outline-none transition-colors"
    style={{ background: on ? 'var(--color-brand)' : 'rgb(255 255 255 / 0.14)' }}
  >
    <span
      className="absolute top-[2px] h-[14px] w-[14px] rounded-full bg-white transition-all"
      style={{ left: on ? 16 : 2 }}
    />
  </button>
);

const CORNERS: { key: Corner; label: string }[] = [
  { key: 'top-left', label: 'Top left' },
  { key: 'top-right', label: 'Top right' },
  { key: 'bottom-left', label: 'Bottom left' },
];

export const SettingsPanel: React.FC<Props> = ({
  settings,
  types,
  tabs,
  timestamps,
  patch,
  setColor,
  onCorner,
  onReset,
}) => (
  <Popover width={300}>
    <div className="shrink-0 border-b border-line px-3 py-2 text-[11px] font-bold tracking-wide text-ink-dim uppercase">
      Chat settings
    </div>

    <div className="min-h-0 flex-1 overflow-y-auto px-3 py-2">
      <Row label="Timestamps">
        <Toggle on={timestamps} onClick={() => patch({ timestamps: !timestamps })} />
      </Row>

      <Row label="Show while closed">
        <Toggle
          on={settings.notifications}
          onClick={() => patch({ notifications: !settings.notifications })}
        />
      </Row>

      <Row label={`Opacity ${Math.round(settings.opacity * 100)}%`}>
        <input
          type="range"
          min={40}
          max={100}
          value={Math.round(settings.opacity * 100)}
          onChange={(event) => patch({ opacity: Number(event.target.value) / 100 })}
          className="h-1 w-[120px] cursor-pointer appearance-none rounded-full bg-raised accent-[var(--color-brand)]"
        />
      </Row>

      <div className="mt-2 mb-1 text-[11px] font-bold tracking-wide text-ink-faint uppercase">
        Position
      </div>
      <div className="flex gap-1">
        {CORNERS.map((corner) => (
          <button
            key={corner.key}
            onClick={() => onCorner(corner.key)}
            className="flex-1 rounded-md border border-line px-2 py-1.5 text-[11px] font-medium text-ink-dim outline-none hover:bg-raised hover:text-ink"
          >
            {corner.label}
          </button>
        ))}
      </div>
      <p className="mt-1.5 text-[11px] text-ink-faint">Or drag the chat by its badge.</p>

      <div className="mt-3 mb-1 text-[11px] font-bold tracking-wide text-ink-faint uppercase">
        Colours
      </div>
      <div className="space-y-1">
        {tabs.map((kind) => {
          const type = types[kind];
          if (!type) return null;
          const value = settings.colors[kind] ?? type.color;

          return (
            <div key={kind} className="flex items-center gap-2">
              <span className="w-16 shrink-0 text-[11px] font-semibold text-ink-dim">{type.label}</span>
              <input
                type="color"
                value={value}
                onChange={(event) => setColor(kind, event.target.value)}
                className="h-6 w-9 cursor-pointer rounded border border-line bg-transparent"
              />
              {settings.colors[kind] && (
                <button
                  onClick={() => setColor(kind, null)}
                  className="text-[11px] text-ink-faint outline-none hover:text-ink"
                >
                  reset
                </button>
              )}
            </div>
          );
        })}
      </div>
    </div>

    <div className="shrink-0 border-t border-line px-3 py-2">
      <button
        onClick={onReset}
        className="w-full rounded-md border border-line py-1.5 text-[11px] font-semibold text-ink-dim outline-none hover:bg-raised hover:text-ink"
      >
        Reset everything
      </button>
    </div>
  </Popover>
);
