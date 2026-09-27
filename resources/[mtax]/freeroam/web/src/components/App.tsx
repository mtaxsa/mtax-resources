import { CircleAlert, CircleCheck, Info, TriangleAlert, X, type LucideIcon } from 'lucide-react';
import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useNuiEvent } from '../hooks/useNuiEvent';
import { useI18n } from '../i18n';
import { fetchNui } from '../utils/fetchNui';
import { isEnvBrowser } from '../utils/misc';
import { ColorWindow } from './ColorWindow';
import { FreeroamContext, type Freeroam } from './context';
import { MainPanel, TOOL_ICONS } from './MainPanel';
import { MapWindow } from './MapWindow';
import {
  AnimationsTool,
  BookmarksTool,
  ClothesTool,
  FightStylesTool,
  GameSpeedTool,
  GravityTool,
  InteriorsTool,
  PaintjobsTool,
  PlayersTool,
  SkinsTool,
  StatsTool,
  TimeTool,
  UpgradesTool,
  VehiclesTool,
  WalksTool,
  WeaponsTool,
  WeatherTool,
  type ToolProps,
} from './tools';
import {
  asArray,
  type Bookmark,
  type BootPayload,
  type ClothesGroup,
  type LiveState,
  type Options,
  type SessionPayload,
  type Toast,
  type ToastKind,
  type ToastPayload,
} from './types';

interface ToolSpec {
  title: string;
  // 'square' makes the drawer as wide as it is tall (the map).
  width: number | 'square';
  Component: React.FC<ToolProps>;
}

const TOOLS: Record<string, ToolSpec> = {
  map: { title: '@window.map', width: 'square', Component: MapWindow },
  vehiclecolor: { title: '@window.vehicle_color', width: 380, Component: ColorWindow },

  skins: { title: '@window.skins', width: 620, Component: SkinsTool },
  animations: { title: '@window.animations', width: 620, Component: AnimationsTool },
  weapons: { title: '@window.weapons', width: 580, Component: WeaponsTool },
  clothes: { title: '@window.clothes', width: 620, Component: ClothesTool },
  stats: { title: '@window.stats', width: 600, Component: StatsTool },
  walks: { title: '@window.walks', width: 440, Component: WalksTool },
  fightstyles: { title: '@window.fightstyles', width: 420, Component: FightStylesTool },
  gravity: { title: '@window.gravity', width: 440, Component: GravityTool },
  players: { title: '@window.players', width: 480, Component: PlayersTool },
  bookmarks: { title: '@window.bookmarks', width: 560, Component: BookmarksTool },
  interiors: { title: '@window.interiors', width: 520, Component: InteriorsTool },

  vehicles: { title: '@window.vehicles', width: 620, Component: VehiclesTool },
  upgrades: { title: '@window.upgrades', width: 580, Component: UpgradesTool },
  paintjobs: { title: '@window.paintjobs', width: 420, Component: PaintjobsTool },

  time: { title: '@window.time', width: 460, Component: TimeTool },
  weather: { title: '@window.weather', width: 440, Component: WeatherTool },
  gamespeed: { title: '@window.gamespeed', width: 440, Component: GameSpeedTool },
};

const PANEL_WIDTH = 340;
const GAP = 12;
const EDGE = 24;
const MAX_HEIGHT = 720;

const BROWSER_BOOT: BootPayload = { language: 'en-US', keys: { panel: 'F1', map: 'F2', jetpack: 'J' } };

const BROWSER_STATE: LiveState = {
  x: 2488.6, y: -1666.2, z: 13.3, interior: 0, dimension: 0,
  vehicle: 'Infernus', driver: true, health: 78, lights: 0,
  jetpack: false, bike: true, warping: false, knifing: false, ghostmode: true, frozen: false,
  hour: 14, minute: 32, skin: 0, gravity: 0.008, speed: 1, fight: 4, dead: false,
};

const TOAST_TIME = 3200;
const TOAST_LIMIT = 5;

const TOAST_STYLE: Record<ToastKind, { icon: LucideIcon; color: string }> = {
  info: { icon: Info, color: 'text-brand' },
  success: { icon: CircleCheck, color: 'text-good' },
  warning: { icon: TriangleAlert, color: 'text-warn' },
  error: { icon: CircleAlert, color: 'text-bad' },
};

const browserTool = () => {
  const id = new URLSearchParams(window.location.search).get('open');
  return id && TOOLS[id] ? id : null;
};

const viewportHeight = () => Math.min(MAX_HEIGHT, window.innerHeight - EDGE * 2);

const App: React.FC = () => {
  const { t, loc, language, setDefault } = useI18n();

  const [boot, setBoot] = useState<BootPayload | null>(isEnvBrowser() ? BROWSER_BOOT : null);
  const [options, setOptions] = useState<Options>({});
  const [bookmarks, setBookmarks] = useState<Bookmark[]>([]);
  const [state, setState] = useState<LiveState | null>(isEnvBrowser() ? BROWSER_STATE : null);
  const [clothes, setClothes] = useState<ClothesGroup[] | null>(null);
  const [panel, setPanel] = useState(isEnvBrowser());
  const [tool, setTool] = useState<string | null>(isEnvBrowser() ? browserTool() : null);
  const [toasts, setToasts] = useState<Toast[]>([]);
  const [height, setHeight] = useState(viewportHeight);

  const toastId = useRef(0);
  const bootedRef = useRef(isEnvBrowser());

  useEffect(() => {
    const onResize = () => setHeight(viewportHeight());
    window.addEventListener('resize', onResize);
    return () => window.removeEventListener('resize', onResize);
  }, []);

  /// Panel and tool drawer

  const open = useCallback((id: string) => {
    if (id === 'main') setPanel(true);
    else if (TOOLS[id]) setTool(id);
  }, []);

  const close = useCallback((id: string) => {
    if (id === 'main') {
      setPanel(false);
      setTool(null);
      return;
    }
    setTool((current) => (current === id ? null : current));
  }, []);

  const toggle = useCallback(
    (id: string) => {
      if (id === 'main') {
        if (panel) close('main');
        else setPanel(true);
        return;
      }
      if (TOOLS[id]) setTool((current) => (current === id ? null : id));
    },
    [panel, close]
  );

  const isOpen = useCallback((id: string) => (id === 'main' ? panel : tool === id), [panel, tool]);

  const report = [panel ? 'main' : '', tool ?? ''].filter(Boolean).join(',');

  useEffect(() => {
    if (!isEnvBrowser()) fetchNui('windows', { ids: report ? report.split(',') : [] });
  }, [report]);

  // If focus ever sticks with nothing open, hand it back to the game.
  useEffect(() => {
    if (report || isEnvBrowser()) return;

    const id = window.setInterval(() => {
      if (document.hasFocus()) fetchNui('windows', { ids: [] });
    }, 1000);

    return () => window.clearInterval(id);
  }, [report]);

  /// Nui

  const applyBoot = useCallback(
    (payload: BootPayload) => {
      if (!payload?.keys) return;
      bootedRef.current = true;
      setBoot(payload);
      setDefault(payload.language);
    },
    [setDefault]
  );

  const applySession = useCallback((payload: SessionPayload) => {
    if (!payload) return;
    setOptions(payload.options ?? {});
    setBookmarks(asArray<Bookmark>(payload.bookmarks));
  }, []);

  const pushToast = useCallback((payload: ToastPayload) => {
    if (!payload?.key) return;

    toastId.current += 1;
    const id = toastId.current;

    setToasts((current) => [...current, { ...payload, id }].slice(-TOAST_LIMIT));
    window.setTimeout(() => setToasts((current) => current.filter((toast) => toast.id !== id)), TOAST_TIME);
  }, []);

  useNuiEvent<BootPayload>('boot', applyBoot);
  useNuiEvent<SessionPayload>('session', applySession);
  useNuiEvent<Options>('options', (payload) => setOptions(payload ?? {}));
  useNuiEvent<Bookmark[]>('bookmarks', (payload) => setBookmarks(asArray<Bookmark>(payload)));
  useNuiEvent<LiveState>('state', setState);
  useNuiEvent<ClothesGroup[]>('clothes', (payload) => setClothes(asArray<ClothesGroup>(payload)));
  useNuiEvent<ToastPayload>('toast', pushToast);
  useNuiEvent<string>('toggle', toggle);
  useNuiEvent<string>('close', close);

  // Tools opened from commands bring the panel along.
  useNuiEvent<string>('open', (id) => {
    open('main');
    open(id);
  });

  useEffect(() => {
    if (isEnvBrowser()) return;

    let cancelled = false;
    let attempts = 0;

    const ask = () => {
      if (cancelled || bootedRef.current) return;
      attempts += 1;

      fetchNui<{ boot?: BootPayload; session?: SessionPayload | false }>('ready')
        .then((reply) => {
          if (cancelled || bootedRef.current) return;

          if (reply?.boot) {
            applyBoot(reply.boot);
            if (reply.session) applySession(reply.session);
            return;
          }

          if (attempts < 40) window.setTimeout(ask, 500);
        })
        .catch(() => {
          if (!cancelled && attempts < 40) window.setTimeout(ask, 500);
        });
    };

    ask();
    return () => {
      cancelled = true;
    };
  }, [applyBoot, applySession]);

  // The knife label is drawn by the client script, so it needs the translated text.
  useEffect(() => {
    if (!isEnvBrowser()) fetchNui('labels', { knife: t('status.knife_disabled') });
  }, [language, t]);

  /// Keyboard

  useEffect(() => {
    if (!boot) return;

    const onKey = (event: KeyboardEvent) => {
      if (event.repeat) return;
      const key = event.key.toUpperCase();

      if (key === boot.keys.panel || key === boot.keys.map) {
        event.preventDefault();
        const id = key === boot.keys.panel ? 'main' : 'map';
        if (isEnvBrowser()) toggle(id);
        else fetchNui('key', { id });
        return;
      }

      if (event.key === 'Escape') {
        event.preventDefault();
        if (tool) close(tool);
        else if (panel) close('main');
      }
    };

    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [boot, tool, panel, toggle, close]);

  const context = useMemo<Freeroam | null>(
    () => (boot ? { boot, options, state, bookmarks, clothes, isOpen, open, close, toggle } : null),
    [boot, options, state, bookmarks, clothes, isOpen, open, close, toggle]
  );

  if (!context) return null;

  const spec = tool ? TOOLS[tool] : null;
  const room = window.innerWidth - EDGE * 2 - (panel ? PANEL_WIDTH + GAP : 0);
  const toolWidth = spec ? Math.min(spec.width === 'square' ? height : spec.width, room) : 0;
  const ToolIcon = tool ? TOOL_ICONS[tool] : null;

  return (
    <FreeroamContext.Provider value={context}>
      <div className="absolute top-1/2 flex -translate-y-1/2 items-stretch" style={{ left: EDGE, height, gap: GAP }}>
        {panel && (
          <aside
            className="interactive animate-[panelIn_0.18s_ease-out] overflow-hidden rounded-2xl border border-line bg-panel shadow-[0_24px_70px_rgb(0_0_0/0.55)]"
            style={{ width: PANEL_WIDTH }}
          >
            <MainPanel onClose={() => close('main')} />
          </aside>
        )}

        {spec && tool && (
          <section
            key={tool}
            className="interactive flex animate-[panelIn_0.18s_ease-out] flex-col overflow-hidden rounded-2xl border border-line bg-panel shadow-[0_24px_70px_rgb(0_0_0/0.55)]"
            style={{ width: toolWidth }}
          >
            <header className="flex h-14 shrink-0 items-center gap-3 border-b border-line px-4">
              {ToolIcon && (
                <span className="flex h-8 w-8 items-center justify-center rounded-lg bg-brand/12">
                  <ToolIcon size={16} strokeWidth={2.2} className="text-brand" />
                </span>
              )}
              <span className="min-w-0 flex-1 truncate text-[14px] font-semibold text-ink">{loc(spec.title)}</span>
              <button
                onClick={() => close(tool)}
                className="flex h-8 w-8 items-center justify-center rounded-lg text-ink-faint outline-none hover:bg-raised hover:text-ink"
              >
                <X size={17} />
              </button>
            </header>
            <spec.Component active />
          </section>
        )}
      </div>

      <div className="pointer-events-none fixed top-5 left-1/2 z-[9000] flex -translate-x-1/2 flex-col items-center gap-2">
        {toasts.map((toast) => {
          const style = TOAST_STYLE[toast.kind ?? 'info'] ?? TOAST_STYLE.info;
          const Icon = style.icon;

          return (
            <div
              key={toast.id}
              className="flex max-w-[480px] animate-[toastIn_0.16s_ease-out] items-center gap-2.5 rounded-xl border border-line bg-panel-solid py-2.5 pr-4 pl-3 text-[13px] font-medium text-ink shadow-[0_12px_36px_rgb(0_0_0/0.5)]"
            >
              <Icon size={17} strokeWidth={2.2} className={`shrink-0 ${style.color}`} />
              {t(toast.key, toast.vars)}
            </div>
          );
        })}
      </div>
    </FreeroamContext.Provider>
  );
};

export default App;
