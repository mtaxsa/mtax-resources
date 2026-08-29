import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useNuiEvent } from '../hooks/useNuiEvent';
import { fetchNui } from '../utils/fetchNui';
import { isEnvBrowser } from '../utils/misc';
import { Composer } from './Chat/Composer';
import { Labels } from './Chat/Labels';
import { MessageRow } from './Chat/MessageRow';
import { Suggestions } from './Chat/Suggestions';
import {
  asArray,
  type BootPayload,
  type ChatMessage,
  type Corner,
  type HistoryRow,
  type RosterEntry,
  type SessionPayload,
  type Suggestion,
  type WorldLabel,
} from './Chat/types';
import { cornerPosition, useSettings, WIDGET_HEIGHT, WIDGET_WIDTH } from './Chat/useSettings';

const BROWSER_BOOT: BootPayload = {
  types: {
    local: { label: 'SAY', color: '#e7e9ee', form: 'said' },
    me: { label: 'ME', color: '#4aa8ff', form: 'action' },
    do: { label: 'DO', color: '#a978ff', form: 'action', fade: 10000 },
    ooc: { label: 'OOC', color: '#3ddc84', form: 'said' },
    global: { label: 'GLOBAL', color: '#ffb020', form: 'said' },
    pm: { label: 'PM', color: '#ff5fa2', form: 'said' },
    dice: { label: 'DICE', color: '#00d1c1', form: 'action' },
    system: { label: 'SYSTEM', color: '#8b93a7', form: 'plain' },
    join: { label: 'JOIN', color: '#3ddc84', form: 'plain' },
    leave: { label: 'LEFT', color: '#ff6b6b', form: 'plain' },
  },
  tabs: ['local', 'me', 'do', 'ooc', 'global', 'pm'],
  defaultTab: 'local',
  suggestions: [
    { name: 'me', params: '[action]', help: 'Describe what you are doing' },
    { name: 'do', params: '[description]', help: 'Describe the scene' },
    { name: 'pm', params: '[id] [message]', help: 'Private message a player' },
  ],
  stickers: [
    '1f44b', '1f44d', '1f44e', '1f44f', '1f64f', '1f4aa',
    '1f600', '1f602', '1f605', '1f60e', '1f610', '1f614',
    '1f621', '1f622', '1f631', '1f634', '1f644', '1f92b',
    '2764', '1f494', '1f525', '1f4a3', '1f3c1', '1f3af',
    '1f697', '1f6a8', '1f52b', '1f48a', '1f4b0', '1f37b',
    '1f355', '1f480',
  ],
  history: 100,
  maxLength: 200,
  hideAfter: 12000,
  timestamps: true,
  openKey: 't',
};

const BROWSER_ROWS: HistoryRow[] = [
  { key: -6, at: Date.now(), kind: 'join', text: 'Frank Hithock joined the server', time: '05:54' },
  { key: -5, at: Date.now(), kind: 'do', name: 'Frank Hithock', pid: 1, text: 'The wind picks up off the pier.', time: '05:56' },
  { key: -4, at: Date.now(), kind: 'me', name: 'Frank Hithock', pid: 1, text: 'waves at the crowd', time: '05:56' },
  { key: -3, at: Date.now(), kind: 'local', name: 'Maria Cortez', pid: 2, text: 'Evening. Long way from the strip.', time: '05:57' },
  { key: -2, at: Date.now(), kind: 'ooc', name: 'Maria Cortez', pid: 2, text: 'brb one sec 🙂', sticker: '1f44b', time: '05:57' },
  { key: -1, at: Date.now(), kind: 'pm', name: 'Maria Cortez', pid: 2, note: 'to', text: 'meet me by the coaster', time: '05:58' },
];

const App: React.FC = () => {
  const [boot, setBoot] = useState<BootPayload | null>(isEnvBrowser() ? BROWSER_BOOT : null);
  const [open, setOpen] = useState(isEnvBrowser());
  const [rows, setRows] = useState<HistoryRow[]>(isEnvBrowser() ? BROWSER_ROWS : []);
  const [labels, setLabels] = useState<WorldLabel[]>([]);
  const [roster, setRoster] = useState<RosterEntry[]>(
    isEnvBrowser() ? [{ id: 1, name: 'Frank Hithock' }, { id: 2, name: 'Maria Cortez' }] : []
  );
  const [enabled, setEnabled] = useState(true);

  const [tab, setTab] = useState('local');
  const [text, setText] = useState('');
  const [target, setTarget] = useState('');

  const [commands, setCommands] = useState<string[]>([]);
  const [commandIndex, setCommandIndex] = useState(-1);
  const [pick, setPick] = useState(0);

  const [dragging, setDragging] = useState(false);
  const [tick, setTick] = useState(0);

  const inputRef = useRef<HTMLInputElement>(null);
  const listRef = useRef<HTMLDivElement>(null);
  const widgetRef = useRef<HTMLDivElement>(null);
  const keyRef = useRef(0);
  const dragRef = useRef({ dx: 0, dy: 0 });

  const { settings, patch, setColor, reset } = useSettings();

  const colorOf = useCallback(
    (kind: string) => settings.colors[kind] ?? boot?.types[kind]?.color ?? '#e7e9ee',
    [settings.colors, boot]
  );

  const close = useCallback(() => {
    setOpen(false);
    fetchNui('close');
  }, []);

  const cycleTab = useCallback(
    (step: number) => {
      const list = asArray<string>(boot?.tabs);
      if (list.length === 0) return;

      const at = list.indexOf(tab);
      setTab(list[((at < 0 ? 0 : at) + step + list.length) % list.length]);
      inputRef.current?.focus();
    },
    [boot, tab]
  );

  const swallow = useRef(0);

  const strayOpenKey = useCallback(
    (value: string) => {
      if (swallow.current === 0 || value.length !== 1) return false;

      if (Date.now() - swallow.current > 300) {
        swallow.current = 0;
        return false;
      }

      if (value.toLowerCase() !== (boot?.openKey ?? '').toLowerCase()) return false;

      swallow.current = 0;
      return true;
    },
    [boot]
  );

  const acceptText = useCallback(
    (value: string) => {
      if (strayOpenKey(value)) return;
      setText(value);
    },
    [strayOpenKey]
  );

  const bootedRef = useRef(isEnvBrowser());

  const applyBoot = useCallback((payload: BootPayload) => {
    if (!payload || !payload.types) return;
    bootedRef.current = true;
    setBoot(payload);
    setTab((current) => (payload.types[current] ? current : payload.defaultTab));
  }, []);

  const applySession = useCallback((payload: SessionPayload) => {
    setRoster(asArray<RosterEntry>(payload?.roster));
    setEnabled(payload?.enabled !== false);
  }, []);

  useNuiEvent<BootPayload>('boot', applyBoot);
  useNuiEvent<SessionPayload>('session', applySession);

  useNuiEvent<boolean>('toggle', setOpen);

  useNuiEvent<ChatMessage>('message', (message) => {
    if (!message || typeof message.text !== 'string') return;

    keyRef.current += 1;
    setRows((current) => {
      const next = [...current, { ...message, key: keyRef.current, at: Date.now() }];
      const limit = boot?.history ?? 100;
      return next.length > limit ? next.slice(next.length - limit) : next;
    });
  });

  useNuiEvent<RosterEntry[]>('roster', (payload) => setRoster(asArray<RosterEntry>(payload)));
  useNuiEvent<boolean>('enabled', (payload) => setEnabled(payload !== false));
  useNuiEvent<WorldLabel[]>('labels', (payload) => setLabels(asArray<WorldLabel>(payload)));

  useNuiEvent<undefined>('clear', () => {
    setRows([]);
    setLabels([]);
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

  useEffect(() => {
    if (!open) {
      setPick(0);
      setCommandIndex(-1);
      return;
    }

    swallow.current = Date.now();

    let stopped = false;
    let attempts = 0;
    let timer = 0;

    const claim = () => {
      if (stopped || attempts >= 40) return;
      attempts += 1;

      const node = inputRef.current;
      if (node) {
        window.focus();
        node.focus({ preventScroll: true });
        if (document.hasFocus() && document.activeElement === node) return;
      }

      timer = window.setTimeout(claim, 50);
    };

    claim();
    return () => {
      stopped = true;
      window.clearTimeout(timer);
    };
  }, [open, boot]);

  useEffect(() => {
    if (!open) return;

    const catchKey = (event: KeyboardEvent) => {
      const node = inputRef.current;
      if (!node || event.defaultPrevented) return;

      if (event.key === 'Escape') {
        event.preventDefault();
        close();
        return;
      }

      if (event.key === 'Tab') {
        event.preventDefault();
        cycleTab(event.shiftKey ? -1 : 1);
        return;
      }

      const from = event.target as HTMLElement | null;
      if (from && (from.isContentEditable || /^(INPUT|TEXTAREA|SELECT)$/.test(from.tagName))) return;

      if (event.ctrlKey || event.altKey || event.metaKey || event.key.length !== 1) return;

      event.preventDefault();
      if (strayOpenKey(event.key)) return;

      node.focus({ preventScroll: true });
      setText((current) => (current + event.key).slice(0, boot?.maxLength ?? 200));
    };

    window.addEventListener('keydown', catchKey);
    return () => window.removeEventListener('keydown', catchKey);
  }, [open, boot, close, cycleTab, strayOpenKey]);

  useEffect(() => {
    if (open || isEnvBrowser()) return;

    const id = window.setInterval(() => {
      if (document.hasFocus()) fetchNui('close');
    }, 1000);

    return () => window.clearInterval(id);
  }, [open]);

  useEffect(() => {
    const node = listRef.current;
    if (node) node.scrollTop = node.scrollHeight;
  }, [rows, open]);

  useEffect(() => {
    if (rows.length === 0) return;
    const id = window.setInterval(() => setTick((value) => value + 1), 1000);
    return () => window.clearInterval(id);
  }, [rows.length]);

  useEffect(() => {
    if (!dragging) return;

    const move = (event: MouseEvent) => {
      patch({
        x: Math.min(Math.max(0, event.clientX - dragRef.current.dx), window.innerWidth - WIDGET_WIDTH),
        y: Math.min(Math.max(0, event.clientY - dragRef.current.dy), window.innerHeight - 80),
      });
    };
    const up = () => setDragging(false);

    window.addEventListener('mousemove', move);
    window.addEventListener('mouseup', up);
    return () => {
      window.removeEventListener('mousemove', move);
      window.removeEventListener('mouseup', up);
    };
  }, [dragging, patch]);

  const suggestions = useMemo<Suggestion[]>(() => {
    if (!open || !boot || !text.startsWith('/')) return [];
    const query = text.slice(1).split(' ')[0].toLowerCase();
    if (text.slice(1).includes(' ')) return [];
    return asArray<Suggestion>(boot.suggestions).filter((item) => item.name.startsWith(query));
  }, [open, boot, text]);

  const send = useCallback(() => {
    const value = text.trim();

    if (value === '') {
      close();
      return;
    }

    if (value.startsWith('/')) {
      const line = value.slice(1).trim();
      if (line !== '') {
        setCommands((current) => [...current.filter((entry) => entry !== value), value].slice(-30));
        fetchNui('command', { line });
      }
    } else {
      fetchNui('send', {
        type: tab,
        text: value,
        target: tab === 'pm' ? target : undefined,
      });
    }

    setText('');
    setCommandIndex(-1);
    close();
  }, [text, tab, target, close]);

  const sendSticker = useCallback(
    (id: string) => {
      fetchNui('send', {
        type: tab,
        text: text.trim(),
        sticker: id,
        target: tab === 'pm' ? target : undefined,
      });
      setText('');
      close();
    },
    [tab, text, target, close]
  );

  const complete = useCallback(
    (item: Suggestion) => {
      setText(`/${item.name} `);
      inputRef.current?.focus();
    },
    []
  );

  const onKeyDown = useCallback(
    (event: React.KeyboardEvent<HTMLInputElement>) => {
      if (event.key === 'Escape') {
        event.preventDefault();
        close();
        return;
      }

      if (event.key === 'Enter') {
        event.preventDefault();
        if (suggestions.length > 0) {
          complete(suggestions[pick]);
          return;
        }
        send();
        return;
      }

      if (event.key === 'Tab') {
        event.preventDefault();
        cycleTab(event.shiftKey ? -1 : 1);
        return;
      }

      if (event.key === 'ArrowUp' || event.key === 'ArrowDown') {
        const step = event.key === 'ArrowUp' ? -1 : 1;

        if (suggestions.length > 0) {
          event.preventDefault();
          setPick((current) => (current + step + suggestions.length) % suggestions.length);
          return;
        }

        if (commands.length === 0) return;
        event.preventDefault();

        const next = Math.min(Math.max(commandIndex - step, -1), commands.length - 1);
        setCommandIndex(next);
        setText(next < 0 ? '' : commands[commands.length - 1 - next]);
      }
    },
    [close, send, complete, cycleTab, suggestions, pick, commands, commandIndex]
  );

  useEffect(() => setPick(0), [suggestions.length]);

  if (!boot) return null;

  const fallback = cornerPosition('top-left');
  const left = settings.x ?? fallback.x;
  const top = settings.y ?? fallback.y;

  const timestamps = settings.timestamps ?? boot.timestamps;
  const hideAfter = boot.hideAfter ?? 0;
  const now = Date.now();
  void tick;

  const visible = rows.filter((row) => {
    if (open) return true;
    if (!settings.notifications) return false;
    return hideAfter <= 0 || now - row.at < hideAfter;
  });

  return (
    <>
    <Labels labels={labels} types={boot.types} colorOf={colorOf} />

    <div
      ref={widgetRef}
      className="absolute"
      style={{
        left,
        top,
        width: WIDGET_WIDTH,
        opacity: settings.opacity,
      }}
    >
      <div
        ref={listRef}
        className={`overflow-x-hidden ${open ? 'interactive overflow-y-auto' : 'overflow-y-hidden'}`}
        style={{ maxHeight: WIDGET_HEIGHT - 96, minHeight: open ? 120 : 0 }}
      >
        <div className="flex min-h-full flex-col justify-end gap-1.5">
          {visible.map((row) => {
            const type = boot.types[row.kind] ?? boot.types.system;
            if (!type) return null;

            return (
              <MessageRow
                key={row.key}
                row={row}
                type={type}
                color={row.color ?? colorOf(row.kind)}
                timestamps={timestamps}
                fresh={now - row.at < 400}
                stale={type.fade !== undefined && now - row.at > type.fade}
              />
            );
          })}
        </div>
      </div>

      {open && (
        <>
          {suggestions.length > 0 && (
            <div className="mt-2">
              <Suggestions items={suggestions} index={pick} onPick={complete} />
            </div>
          )}

          {!enabled && (
            <div className="interactive mt-2 rounded-lg border border-line bg-panel-solid px-3 py-2 text-[12px] text-ink-dim">
              The chat is off. Only admins can talk right now.
            </div>
          )}

          <Composer
            types={boot.types}
            tabs={boot.tabs}
            tab={tab}
            setTab={setTab}
            text={text}
            setText={acceptText}
            target={target}
            setTarget={setTarget}
            maxLength={boot.maxLength}
            stickers={asArray<string>(boot.stickers)}
            inputRef={inputRef}
            onKeyDown={onKeyDown}
            onSend={send}
            onSticker={sendSticker}
            onDice={() => {
              fetchNui('command', { line: 'dice' });
              close();
            }}
            onDragStart={(event) => {
              const host = widgetRef.current?.getBoundingClientRect();
              dragRef.current = {
                dx: event.clientX - (host?.left ?? left),
                dy: event.clientY - (host?.top ?? top),
              };
              setDragging(true);
            }}
            colorOf={colorOf}
            settings={settings}
            timestamps={timestamps}
            patch={patch}
            setColor={setColor}
            onCorner={(corner: Corner) => patch(cornerPosition(corner))}
            onReset={reset}
          />

          {roster.length > 0 && tab === 'pm' && (
            <div className="interactive mt-2 flex flex-wrap gap-1 rounded-lg border border-line bg-panel px-2 py-1.5">
              {roster.map((entry) => (
                <button
                  key={entry.id}
                  onMouseDown={(event) => event.preventDefault()}
                  onClick={() => {
                    setTarget(String(entry.id));
                    inputRef.current?.focus();
                  }}
                  className="rounded px-1.5 py-0.5 text-[11px] text-ink-dim outline-none hover:bg-raised hover:text-ink"
                  style={{ background: target === String(entry.id) ? 'var(--color-raised)' : undefined }}
                >
                  <b className="text-ink">{entry.id}</b> {entry.name}
                </button>
              ))}
            </div>
          )}
        </>
      )}
    </div>
    </>
  );
};

export default App;
