import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useNuiEvent } from '../hooks/useNuiEvent';
import { isEnvBrowser } from '../utils/misc';

type LogLevel = 'debug' | 'info' | 'success' | 'erro';
type Side = 'client' | 'server';

interface LogEntry {
  id: number;
  level: LogLevel;
  text: string;
  time: string;
  count: number;
  side: Side;
}

interface IncomingLog {
  level: LogLevel;
  text: string;
  side: Side;
}

const LEVELS: { key: LogLevel; label: string; tag: string; color: string }[] = [
  { key: 'success', label: 'Info', tag: 'DEBUG', color: '#89d185' },
  { key: 'info', label: 'Warning', tag: 'INFO', color: '#E69138' },
  { key: 'erro', label: 'Erro', tag: 'ERROR', color: '#f14c4c' },
];

const SIDES: { key: Side; label: string }[] = [
  { key: 'client', label: 'CLIENT' },
  { key: 'server', label: 'SERVER' },
];

const FLOOD_LIMIT = 1000;


const pickLevel = (): LogLevel => {
  const weights: [LogLevel, number][] = [
    ['debug', 0.3],
    ['info', 0.35],
    ['success', 0.25],
    ['erro', 0.1],
  ];
  const r = Math.random();
  let acc = 0;
  for (const [level, w] of weights) {
    acc += w;
    if (r <= acc) return level;
  }
  return 'info';
};

const App: React.FC = () => {
  const [show, setShow] = useState(false);
  const [expanded, setExpanded] = useState(false);
  const [paused, setPaused] = useState(false);
  const [activeSide, setActiveSide] = useState<Side>('client');
  const [entries, setEntries] = useState<LogEntry[]>([]);
  const [filters, setFilters] = useState<Record<LogLevel, boolean>>({
    debug: true,
    info: true,
    success: true,
    erro: true,
  });
  const [search, setSearch] = useState('');

  const [position, setPosition] = useState<{ x: number; y: number } | null>(null);
  const [dragging, setDragging] = useState(false);
  const [copiedId, setCopiedId] = useState<number | null>(null);

  const logRef = useRef<HTMLDivElement>(null);
  const panelRef = useRef<HTMLDivElement>(null);
  const autoscrollRef = useRef(true);
  const idRef = useRef(0);
  const pausedRef = useRef(paused);
  const floodRef = useRef<{ remaining: number; level: LogLevel; text: string } | null>(null);
  const copyTimeoutRef = useRef<number | null>(null);

  useNuiEvent<boolean>('toggle', setShow);

  useNuiEvent<IncomingLog>('addLog', ({ level, text, side }) => {
    addLog(level, text, side);
  });

  useEffect(() => {
    pausedRef.current = paused;
  }, [paused]);

  const addLog = useCallback((level: LogLevel, text: string, side: Side) => {
    if (pausedRef.current) return;
    const time = new Date().toLocaleTimeString('pt-BR', { hour12: false });
    setEntries((prev) => {
      const last = prev[prev.length - 1];
      if (last && last.level === level && last.text === text && last.side === side) {
        const count = last.count + 1;
        if (count > FLOOD_LIMIT) {
          idRef.current = 0;
          return [];
        }
        const next = prev.slice(0, -1);
        next.push({ ...last, count, time });
        return next;
      }
      const next = [...prev, { id: idRef.current++, level, text, time, count: 1, side }];
      return next.length > 300 ? next.slice(next.length - 300) : next;
    });
  }, []);

  const handleDragStart = useCallback((e: React.MouseEvent<HTMLDivElement>) => {
    if (e.button !== 0) return;
    const rect = panelRef.current?.getBoundingClientRect();
    if (!rect) return;
    const offsetX = e.clientX - rect.left;
    const offsetY = e.clientY - rect.top;
    setDragging(true);

    const handleMove = (ev: MouseEvent) => {
      const width = panelRef.current?.offsetWidth ?? rect.width;
      const height = panelRef.current?.offsetHeight ?? rect.height;
      const x = Math.min(Math.max(0, ev.clientX - offsetX), window.innerWidth - width);
      const y = Math.min(Math.max(0, ev.clientY - offsetY), window.innerHeight - height);
      setPosition({ x, y });
    };
    const handleUp = () => {
      setDragging(false);
      window.removeEventListener('mousemove', handleMove);
      window.removeEventListener('mouseup', handleUp);
    };
    window.addEventListener('mousemove', handleMove);
    window.addEventListener('mouseup', handleUp);
  }, []);

  const handleCopy = useCallback((entry: LogEntry) => {
    const text = entry.text;
    const fallbackCopy = () => {
      const ta = document.createElement('textarea');
      ta.value = text;
      ta.style.position = 'fixed';
      ta.style.opacity = '0';
      document.body.appendChild(ta);
      ta.select();
      try {
        document.execCommand('copy');
      } finally {
        document.body.removeChild(ta);
      }
    };

    if (navigator.clipboard?.writeText) {
      navigator.clipboard.writeText(text).catch(fallbackCopy);
    } else {
      fallbackCopy();
    }

    setCopiedId(entry.id);
    if (copyTimeoutRef.current) window.clearTimeout(copyTimeoutRef.current);
    copyTimeoutRef.current = window.setTimeout(() => setCopiedId(null), 1000);
  }, []);

  useEffect(() => {
    if (!isEnvBrowser()) return;

    const timer = setInterval(() => {
      if (pausedRef.current) return;
      const side: Side = Math.random() < 0.6 ? 'client' : 'server';
      const flood = floodRef.current;

      if (flood && flood.remaining > 0) {
        addLog(flood.level, flood.text, side);
        floodRef.current = { ...flood, remaining: flood.remaining - 1 };
        return;
      }
    }, 900);

    return () => clearInterval(timer);
  }, [addLog]);

  useEffect(() => {
    if (autoscrollRef.current && logRef.current) {
      logRef.current.scrollTop = logRef.current.scrollHeight;
    }
  }, [entries]);

  const handleLogScroll = (e: React.UIEvent<HTMLDivElement>) => {
    const el = e.currentTarget;
    autoscrollRef.current = el.scrollHeight - el.scrollTop - el.clientHeight < 40;
  };

  const toggleLevel = (key: LogLevel) => setFilters((f) => ({ ...f, [key]: !f[key] }));

  const counts = useMemo(() => {
    const c: Record<LogLevel, number> = { debug: 0, info: 0, success: 0, erro: 0 };
    entries.forEach((e) => {
      c[e.level] += 1;
    });
    return c;
  }, [entries]);

  const sideCounts = useMemo(
    () => ({
      client: entries.filter((e) => e.side === 'client').length,
      server: entries.filter((e) => e.side === 'server').length,
    }),
    [entries]
  );

  const visibleEntries = useMemo(() => {
    const query = search.toLowerCase();
    return entries.filter(
      (e) => e.side === activeSide && filters[e.level] && (!query || e.text.toLowerCase().includes(query))
    );
  }, [entries, activeSide, filters, search]);

  if (!show) return null;

  if (!expanded) {
    return (
      <button
        onClick={() => setExpanded(true)}
        className="fixed bottom-5 left-5 z-50 flex items-center gap-2 rounded-full border border-[#2d2d2d] bg-[#1e1e1e] px-3.5 py-2 font-mono text-xs text-[#cccccc] outline-none hover:border-[#3c3c3c]"
      >
        <span
          className="inline-block h-1.5 w-1.5 rounded-full"
          style={{
            background: paused ? '#6a6a6a' : '#89d185',
            animation: paused ? 'none' : 'blinkDot 1.4s ease-in-out infinite',
          }}
        />
        <span className="font-semibold">Debug</span>
        <span className="text-[#6a6a6a]">{entries.length}</span>
      </button>
    );
  }

  return (
    <div
      ref={panelRef}
      className="fixed z-50 flex h-80 w-[580px] flex-col overflow-hidden border border-[#2d2d2d] bg-[#1e1e1e] font-mono shadow-[0_16px_40px_rgba(0,0,0,0.55)]"
      style={position ? { left: position.x, top: position.y } : { left: 20, bottom: 20 }}
    >
      <div
        onMouseDown={handleDragStart}
        className="flex h-[34px] flex-shrink-0 items-stretch border-b border-[#2d2d2d] bg-[#252526]"
        style={{ cursor: dragging ? 'grabbing' : 'grab' }}
      >
        {SIDES.map((side) => {
          const active = activeSide === side.key;
          return (
            <button
              key={side.key}
              onMouseDown={(e) => e.stopPropagation()}
              onClick={() => setActiveSide(side.key)}
              className="flex items-center gap-1.5 border-r border-[#2d2d2d] px-3.5 text-xs font-semibold outline-none"
              style={{
                background: active ? '#1e1e1e' : '#252526',
                color: active ? '#ffffff' : '#808080',
                borderTop: `2px solid ${active ? '#007acc' : 'transparent'}`,
              }}
            >
              {side.label} <span className="font-normal opacity-60">{sideCounts[side.key]}</span>
            </button>
          );
        })}
        <div className="flex-1" />
        <div className="flex items-center gap-0.5 px-2">
          <button
            onMouseDown={(e) => e.stopPropagation()}
            onClick={() => setPaused((p) => !p)}
            title={paused ? 'retomar' : 'pausar'}
            className="flex h-6 w-6 items-center justify-center rounded text-[13px] text-[#cccccc] outline-none hover:bg-[#3c3c3c]"
          >
            {paused ? '▶' : '⏸'}
          </button>
          <button
            onMouseDown={(e) => e.stopPropagation()}
            onClick={() => setEntries([])}
            title="limpar"
            className="flex h-6 w-6 items-center justify-center rounded text-[13px] text-[#cccccc] outline-none hover:bg-[#3c3c3c]"
          >
            ⌫
          </button>
          <button
            onMouseDown={(e) => e.stopPropagation()}
            onClick={() => setExpanded(false)}
            title="fechar"
            className="flex h-6 w-6 items-center justify-center rounded text-[15px] text-[#cccccc] outline-none hover:bg-[#3c3c3c]"
          >
            ×
          </button>
        </div>
      </div>

      <div className="flex items-center gap-1.5 border-b border-[#2d2d2d] bg-[#1e1e1e] px-2.5 py-1.5">
        <input
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Filtrar (ex.: backup, login)"
          className="flex-1 rounded-sm border border-[#3c3c3c] bg-[#3c3c3c] px-2 py-1 text-xs text-[#cccccc] outline-none placeholder:text-[#8a8a8a]"
        />
      </div>

      <div className="flex flex-wrap gap-1.5 border-b border-[#2d2d2d] px-2.5 py-1.5">
        {LEVELS.map((level) => {
          const active = filters[level.key];
          return (
            <button
              key={level.key}
              onClick={() => toggleLevel(level.key)}
              className="rounded-sm px-2 py-0.5 text-[11px] font-semibold outline-none"
              style={{
                border: `1px solid ${active ? level.color : '#3c3c3c'}`,
                background: active ? `${level.color}1a` : 'transparent',
                color: active ? level.color : '#6a6a6a',
              }}
            >
              {level.tag} <span className="font-normal opacity-65">{counts[level.key]}</span>
            </button>
          );
        })}
      </div>

      <div ref={logRef} onScroll={handleLogScroll} className="flex-1 overflow-y-auto py-1">
        {visibleEntries.length === 0 && (
          <div className="py-5 text-center text-xs text-[#6a6a6a]">nenhuma mensagem corresponde aos filtros</div>
        )}
        {visibleEntries.map((entry) => {
          const meta = LEVELS.find((l) => l.key === entry.level)!;
          return (
            <div
              key={entry.id}
              className="group flex animate-[fadeInLog_0.15s_ease-out] items-baseline gap-2 px-2.5 py-px text-[12.5px] leading-normal hover:bg-[#2a2d2e]"
            >
              <span className="w-14 flex-shrink-0 text-[10.5px] text-[#6a6a6a]">{entry.time}</span>
              <span className="w-[52px] flex-shrink-0 text-[11px] font-bold" style={{ color: meta.color }}>
                {meta.tag}
              </span>
              <span className="flex-1 break-words text-[#cccccc]">{entry.text}</span>
              {entry.count > 1 && (
                <span className="flex-shrink-0 text-[11px] font-bold text-[#6a6a6a]">×{entry.count}</span>
              )}
              <button
                onClick={() => handleCopy(entry)}
                title="copiar mensagem"
                className="flex h-4 w-4 flex-shrink-0 items-center justify-center rounded text-[11px] text-[#6a6a6a] opacity-0 outline-none hover:bg-[#3c3c3c] hover:text-[#cccccc] group-hover:opacity-100"
              >
                {copiedId === entry.id ? '✓' : '⧉'}
              </button>
            </div>
          );
        })}
      </div>
    </div>
  );
};

export default App;
