import React, { useCallback, useEffect, useRef, useState } from 'react';
import { useNuiEvent, useNuiKeyboard } from '../hooks';
import { isEnvBrowser } from '../utils/misc';
import { fetchNui } from '../utils/fetchNui';

interface ResourceStat {
  name: string;
  value: number;
}

interface ResourceUpdate {
  client: ResourceStat[];
  server: ResourceStat[];
}

type StatsRow = [string, string, ...unknown[]];

const parseStatsRows = (rows: StatsRow[]): ResourceStat[] =>
  rows
    .filter((row) => Array.isArray(row) && row[0])
    .map((row) => ({
      name: String(row[0]),
      value: parseFloat(String(row[1]).replace('%', '')) || 0,
    }));

interface Point {
  x: number;
  y: number;
}

const MOCK_SERVER: ResourceStat[] = [{ name: 'admin', value: 0.32 }];

interface ResourcePanelProps {
  title: string;
  dotColor: string;
  items: ResourceStat[];
  defaultPosition: Point;
}

const ResourcePanel: React.FC<ResourcePanelProps> = ({ title, dotColor, items, defaultPosition }) => {
  const [position, setPosition] = useState<Point>(defaultPosition);
  const [collapsed, setCollapsed] = useState(false);
  const [dragging, setDragging] = useState(false);
  const panelRef = useRef<HTMLDivElement>(null);

  const handleDragStart = useCallback((e: React.MouseEvent<HTMLDivElement>) => {
    if (e.button !== 0) return;
    if ((e.target as HTMLElement).closest('[data-toggle]')) return;

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

  return (
    <div
      ref={panelRef}
      onMouseDown={handleDragStart}
      className="absolute w-[280px] rounded-xl border border-white/[0.08] p-[10px_14px_14px] shadow-[0_12px_32px_rgba(0,0,0,0.4)] backdrop-blur-[10px]"
      style={{
        left: position.x,
        top: position.y,
        background: 'rgba(18,20,26,0.55)',
        cursor: dragging ? 'grabbing' : 'grab',
        userSelect: dragging ? 'none' : undefined,
      }}
    >
      <div
        data-toggle
        onClick={() => setCollapsed((c) => !c)}
        className="flex select-none items-center justify-between px-0.5 pb-2.5 pt-0.5 cursor-pointer"
      >
        <div className="flex items-baseline gap-[7px]">
          <span className="inline-block h-1.5 w-1.5 rounded-full" style={{ background: dotColor }} />
          <span className="text-[15px] font-semibold tracking-[0.2px] text-[#e8eaed]">{title}</span>
          <span className="text-[13px] font-medium text-white/40">({items.length})</span>
        </div>
        <span
          className="text-[11px] text-white/40 transition-transform duration-150"
          style={{ transform: collapsed ? 'rotate(-90deg)' : 'none' }}
        >
          ▾
        </span>
      </div>

      {!collapsed && (
        <div className="flex flex-col gap-2">
          {items.map((item) => (
            <div
              key={item.name}
              className="flex items-center justify-between rounded-lg border border-white/[0.08] bg-white/[0.04] px-3.5 py-2.5 backdrop-blur-[6px]"
            >
              <div className="flex items-center gap-2.5">
                <span
                  className="inline-block h-2 w-2 flex-shrink-0 rounded-full bg-[#22c55e]"
                  style={{ animation: 'resourcePulse 2.4s ease-in-out infinite' }}
                />
                <span className="font-mono text-[13.5px] text-[#e8eaed]">{item.name}</span>
              </div>
              <span className="text-[13px] tabular-nums text-white/55">{item.value.toFixed(2)}%</span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

const App: React.FC = () => {
  const [show, setShow] = useState(false);
  const [clientStats, setClientStats] = useState<ResourceStat[]>([]);
  const [serverStats, setServerStats] = useState<ResourceStat[]>([]);

  useNuiEvent<boolean>('toggle', setShow);
  useNuiEvent<ResourceUpdate>('updateResources', ({ client, server }) => {
    setClientStats(client);
    setServerStats(server);
  });
  useNuiEvent<StatsRow[]>('stats:client', (rows) => {
    setClientStats(parseStatsRows(rows));
  });
  useNuiEvent<StatsRow[]>('stats:server', (rows) => {
    setServerStats(parseStatsRows(rows));
  });
  useNuiKeyboard('x', () => {
    fetchNui('closeNui');
  });

  useEffect(() => {
    if (!isEnvBrowser()) return;

    const timer = setInterval(() => {
      const jitter = (v: number) => Math.max(0, +(v + (Math.random() - 0.5) * 0.6).toFixed(2));
      setClientStats((prev) => prev.map((s) => ({ ...s, value: jitter(s.value) })));
      setServerStats((prev) => prev.map((s) => ({ ...s, value: jitter(s.value) })));
    }, 1500);

    return () => clearInterval(timer);
  }, []);

  if (!show) return null;

  return (
    <div className="relative h-screen w-screen overflow-hidden">
      <ResourcePanel title="Client-side" dotColor="#5aa8ff" items={clientStats} defaultPosition={{ x: 40, y: 40 }} />
      <ResourcePanel title="Server-side" dotColor="#a855f7" items={serverStats} defaultPosition={{ x: 40, y: 300 }} />
    </div>
  );
};

export default App;
