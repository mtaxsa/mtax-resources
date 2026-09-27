import {
  Bike,
  Bookmark,
  CarFront,
  ChartNoAxesColumn,
  Clock,
  CloudSun,
  Crosshair,
  DoorOpen,
  Footprints,
  Gauge,
  Ghost,
  Lightbulb,
  LightbulbOff,
  Map,
  Navigation,
  Orbit,
  Paintbrush,
  Palette,
  PersonStanding,
  Plane,
  RotateCcw,
  Settings2,
  ShieldOff,
  Shirt,
  Skull,
  Snowflake,
  Swords,
  UserRound,
  Users,
  Wrench,
  X,
  type LucideIcon,
} from 'lucide-react';
import React, { useRef, useState } from 'react';
import { useWheelScroll } from '../hooks/useWheelScroll';
import { useI18n } from '../i18n';
import { fetchNui } from '../utils/fetchNui';
import { useFreeroam } from './context';
import { Card, Tile, ToggleRow } from './ui';

type Tab = 'player' | 'vehicle' | 'world';

interface Tool {
  label: string;
  icon: LucideIcon;
  window?: string;
  run?: string;
  vehicle?: boolean;
}

export const TOOL_ICONS: Record<string, LucideIcon> = {
  skins: UserRound,
  animations: PersonStanding,
  weapons: Crosshair,
  clothes: Shirt,
  stats: ChartNoAxesColumn,
  walks: Footprints,
  gravity: Orbit,
  fightstyles: Swords,
  players: Users,
  bookmarks: Bookmark,
  interiors: DoorOpen,
  map: Map,
  vehicles: CarFront,
  upgrades: Settings2,
  vehiclecolor: Palette,
  paintjobs: Paintbrush,
  time: Clock,
  weather: CloudSun,
  gamespeed: Gauge,
};

const tool = (label: string, window: string, extra: Partial<Tool> = {}): Tool => ({
  label,
  window,
  icon: TOOL_ICONS[window],
  ...extra,
});

const PLAYER_TOOLS: Tool[] = [
  tool('main.skin', 'skins'),
  tool('main.animation', 'animations'),
  tool('main.weapon', 'weapons'),
  tool('main.clothes', 'clothes'),
  tool('main.stats', 'stats'),
  tool('main.walk', 'walks'),
  tool('main.gravity', 'gravity'),
  tool('main.fight', 'fightstyles'),
];

const VEHICLE_TOOLS: Tool[] = [
  tool('main.create', 'vehicles'),
  { label: 'main.repair', icon: Wrench, run: 'repair', vehicle: true },
  { label: 'main.flip', icon: RotateCcw, run: 'flip', vehicle: true },
  tool('main.upgrades', 'upgrades', { vehicle: true }),
  tool('main.color', 'vehiclecolor', { vehicle: true }),
  tool('main.paintjob', 'paintjobs', { vehicle: true }),
];

const WORLD_TOOLS: Tool[] = [
  tool('main.map', 'map'),
  tool('main.interior', 'interiors'),
  tool('main.players', 'players'),
  tool('main.bookmarks', 'bookmarks'),
  tool('main.time', 'time'),
  tool('main.weather', 'weather'),
  tool('main.speed', 'gamespeed'),
];

const TABS: { id: Tab; label: string }[] = [
  { id: 'player', label: 'section.player' },
  { id: 'vehicle', label: 'section.vehicle' },
  { id: 'world', label: 'section.environment' },
];

const pad = (value: number) => String(value).padStart(2, '0');

const setToggle = (key: string, value: boolean) => fetchNui('toggle', { key, value });

let savedTab: Tab = 'player';

export const MainPanel: React.FC<{ onClose: () => void }> = ({ onClose }) => {
  const { t, language, cycleLanguage } = useI18n();
  const { boot, options, state, isOpen, toggle } = useFreeroam();
  const [tab, setTab] = useState<Tab>(savedTab);
  const bodyRef = useRef<HTMLDivElement>(null);

  useWheelScroll(bodyRef);

  const inVehicle = Boolean(state?.vehicle);
  const health = state?.health ?? 0;
  const tone = health > 50 ? 'var(--color-good)' : health > 20 ? 'var(--color-warn)' : 'var(--color-bad)';

  const pickTab = (next: Tab) => {
    savedTab = next;
    setTab(next);
  };

  const grid = (tools: Tool[], extra?: React.ReactNode) => (
    <div className="grid grid-cols-3 gap-2">
      {tools.map((entry) => (
        <Tile
          key={entry.label}
          icon={entry.icon}
          label={t(entry.label)}
          active={entry.window ? isOpen(entry.window) : false}
          disabled={entry.vehicle && !inVehicle}
          onClick={() => (entry.window ? toggle(entry.window) : fetchNui(entry.run!))}
        />
      ))}
      {extra}
    </div>
  );

  return (
    <div className="flex h-full flex-col">
      <header className="flex shrink-0 items-center gap-3 px-4 pt-4 pb-3">
        <div className="bg-accent flex h-9 w-9 items-center justify-center rounded-xl shadow-[0_6px_18px_rgb(255_77_141/0.35)]">
          {/* The arrow's mass sits up and to the right of its 24px box; nudge it back to the optical centre. */}
          <Navigation size={18} strokeWidth={2.4} className="text-white" style={{ translate: '-1.25px 1.25px' }} />
        </div>
        <div className="min-w-0 flex-1 leading-tight">
          <div className="text-[15px] font-bold text-ink">Freeroam</div>
          <div className="text-[11px] font-semibold tracking-[0.2em] text-ink-faint">MTAX</div>
        </div>
        <button
          onClick={onClose}
          className="flex h-8 w-8 items-center justify-center rounded-lg text-ink-faint outline-none hover:bg-raised hover:text-ink"
        >
          <X size={17} />
        </button>
      </header>

      <div className="mx-4 mb-3 rounded-xl border border-line bg-surface px-3.5 py-3">
        <div className="flex items-center justify-between gap-2">
          <div className="flex min-w-0 items-center gap-3 text-[12.5px] tabular-nums">
            {state ? (
              (['x', 'y', 'z'] as const).map((axis) => (
                <span key={axis} className="text-ink">
                  <span className="mr-1 text-[11px] font-semibold text-ink-faint uppercase">{axis}</span>
                  {state[axis].toFixed(1)}
                </span>
              ))
            ) : (
              <span className="text-ink-faint">{t('common.no_position')}</span>
            )}
          </div>
          {state && (
            <span className="shrink-0 rounded-md bg-white/6 px-1.5 py-0.5 text-[11px] text-ink-dim">
              {t('main.interior_short', { id: state.interior })}
            </span>
          )}
        </div>

        <div className="mt-2.5 flex items-center gap-2.5">
          {inVehicle ? <CarFront size={15} className="shrink-0 text-ink-dim" /> : <Footprints size={15} className="shrink-0 text-ink-dim" />}
          <span className="min-w-0 flex-1 truncate text-[12.5px] text-ink">{state?.vehicle || t('common.on_foot')}</span>
          {inVehicle && (
            <>
              <div className="h-1.5 w-20 overflow-hidden rounded-full bg-white/8">
                <i className="block h-full rounded-full transition-[width]" style={{ width: `${Math.max(2, health)}%`, background: tone }} />
              </div>
              <b className="w-9 text-right text-[12px] font-semibold tabular-nums" style={{ color: tone }}>
                {health}%
              </b>
            </>
          )}
        </div>
      </div>

      <div className="mx-4 mb-3 flex shrink-0 gap-1 rounded-xl bg-black/30 p-1">
        {TABS.map((entry) => (
          <button
            key={entry.id}
            onClick={() => pickTab(entry.id)}
            className={`h-8 flex-1 rounded-lg text-[11.5px] font-bold tracking-wider outline-none transition ${
              tab === entry.id ? 'bg-raised text-ink shadow' : 'text-ink-faint hover:text-ink-dim'
            }`}
          >
            {t(entry.label)}
          </button>
        ))}
      </div>

      <div ref={bodyRef} className="min-h-0 flex-1 overflow-y-auto px-4 pb-4">
        {tab === 'player' && (
          <>
            {grid(
              PLAYER_TOOLS,
              <Tile
                icon={Skull}
                label={t('main.suicide')}
                danger
                disabled={options.kill === false}
                onClick={() => fetchNui('suicide')}
              />
            )}

            <Card className="mt-3 divide-y divide-line">
              <ToggleRow
                icon={Plane}
                label={t('main.jetpack')}
                on={state?.jetpack ?? false}
                disabled={options.jetpack === false}
                onChange={(next) => setToggle('jetpack', next)}
              />
              <ToggleRow icon={Bike} label={t('main.fall_bike')} on={state?.bike ?? true} onChange={(next) => setToggle('bike', next)} />
              <ToggleRow
                icon={ShieldOff}
                label={t('main.block_warp')}
                on={state?.warping ?? false}
                disabled={options.gui?.disablewarp === false}
                onChange={(next) => setToggle('warping', next)}
              />
              <ToggleRow
                icon={Swords}
                label={t('main.block_knife')}
                on={state?.knifing ?? false}
                disabled={options.gui?.disableknife === false}
                onChange={(next) => setToggle('knifing', next)}
              />
              <ToggleRow
                icon={Ghost}
                label={t('main.antiram')}
                on={state?.ghostmode ?? false}
                disabled={options.gui?.antiram === false}
                onChange={(next) => setToggle('ghostmode', next)}
              />
            </Card>
          </>
        )}

        {tab === 'vehicle' && (
          <>
            {grid(VEHICLE_TOOLS)}

            <Card className="mt-3 divide-y divide-line">
              {inVehicle ? (
                <>
                  <ToggleRow
                    icon={Lightbulb}
                    label={t('main.lights_on')}
                    on={state?.lights === 2}
                    onChange={(next) => fetchNui('lights', { mode: next ? 2 : 0 })}
                  />
                  <ToggleRow
                    icon={LightbulbOff}
                    label={t('main.lights_off')}
                    on={state?.lights === 1}
                    onChange={(next) => fetchNui('lights', { mode: next ? 1 : 0 })}
                  />
                </>
              ) : (
                <div className="px-3.5 py-3 text-[12.5px] text-ink-faint">{t('main.enter_vehicle_lights')}</div>
              )}
            </Card>
          </>
        )}

        {tab === 'world' && (
          <>
            {grid(WORLD_TOOLS)}

            <Card className="mt-3">
              <ToggleRow
                icon={Snowflake}
                label={t('main.freeze_time')}
                on={state?.frozen ?? false}
                onChange={(next) => setToggle('frozen', next)}
              />
              <div className="flex items-center justify-between border-t border-line px-3.5 py-2.5">
                <span className="flex items-center gap-3 text-[13px] text-ink">
                  <Clock size={16} className="text-ink-faint" />
                  {t('main.time')}
                </span>
                <span className="text-[15px] font-semibold text-ink tabular-nums">
                  {state ? `${pad(state.hour)}:${pad(state.minute)}` : '--:--'}
                </span>
              </div>
            </Card>
          </>
        )}
      </div>

      <footer className="flex shrink-0 items-center gap-1.5 border-t border-line px-4 py-3 text-[11.5px] text-ink-faint">
        {[
          [boot.keys.panel, 'main.panel_hint'],
          [boot.keys.map, 'main.map_hint'],
          [boot.keys.jetpack, 'main.jetpack_hint'],
        ].map(([key, label]) => (
          <React.Fragment key={label}>
            <kbd className="rounded-md bg-white/8 px-1.5 py-0.5 font-sans text-[10.5px] font-bold text-ink-dim">{key}</kbd>
            <span className="mr-1.5">{t(label)}</span>
          </React.Fragment>
        ))}
        <button
          onClick={cycleLanguage}
          title={t('language.tooltip', { language: language.meta.name })}
          className="ml-auto rounded-md bg-white/8 px-2 py-0.5 text-[10.5px] font-bold text-ink-dim outline-none hover:bg-white/14 hover:text-ink"
        >
          {language.meta.code.split('-')[0].toUpperCase()}
        </button>
      </footer>
    </div>
  );
};
