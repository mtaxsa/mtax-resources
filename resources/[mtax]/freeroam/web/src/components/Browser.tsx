import { Search } from 'lucide-react';
import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useWheelScroll } from '../hooks/useWheelScroll';
import { useI18n } from '../i18n';
import { Button, Input } from './ui';

export interface Row {
  key: string;
  name: string;
  group?: string;
  search?: string;
  sub?: string;
  right?: string;
  tone?: 'ok' | 'muted';
  fields?: Record<string, string>;
}

export interface Field {
  id: string;
  label: string;
  initial: string;
  width?: number;
  text?: boolean;
  placeholder?: string;
  max?: number;
}

export interface Action<R extends Row> {
  label: string | ((row: R | undefined) => string);
  variant?: 'primary' | 'danger';
  free?: boolean;
  run: (row: R | undefined, values: Record<string, string>) => void;
}

interface Props<R extends Row> {
  id: string;
  rows: R[];
  actions: Action<R>[];
  active: boolean;
  fields?: Field[];
  empty?: string;
  search?: string;
}

interface Memory {
  category: string;
  query: string;
  selected: string | null;
  values: Record<string, string>;
}

const OVERSCAN = 4;
const DOUBLE_CLICK = 400;

// Survives closing and reopening a window during the session.
const memory = new Map<string, Memory>();

const remember = (id: string, fields: Field[]): Memory => {
  let entry = memory.get(id);
  if (!entry) {
    entry = {
      category: '',
      query: '',
      selected: null,
      values: Object.fromEntries(fields.map((field) => [field.id, field.initial])),
    };
    memory.set(id, entry);
  }
  return entry;
};

export function Browser<R extends Row>({ id, rows, actions, active, fields = [], empty, search }: Props<R>) {
  const { t, loc } = useI18n();
  const initial = useMemo(() => remember(id, fields), [id]); // eslint-disable-line react-hooks/exhaustive-deps

  const [category, setCategory] = useState(initial.category);
  const [query, setQuery] = useState(initial.query);
  const [selected, setSelected] = useState(initial.selected);
  const [values, setValues] = useState(initial.values);
  const [scroll, setScroll] = useState(0);
  const [height, setHeight] = useState(300);

  const listRef = useRef<HTMLDivElement>(null);
  const categoryRef = useRef<HTMLDivElement>(null);
  const clickRef = useRef({ key: '', at: 0 });

  useWheelScroll(listRef);
  useWheelScroll(categoryRef);

  useEffect(() => {
    memory.set(id, { category, query, selected, values });
  }, [id, category, query, selected, values]);

  const categories = useMemo(() => {
    const order: string[] = [];
    const counts = new Map<string, number>();

    for (const row of rows) {
      if (!row.group) continue;
      const parts = row.group.split('/');

      for (let depth = 1; depth <= parts.length; depth += 1) {
        const key = parts.slice(0, depth).join('/');
        if (!counts.has(key)) order.push(key);
        counts.set(key, (counts.get(key) ?? 0) + 1);
      }
    }

    return order.map((key) => ({
      key,
      label: key.split('/').pop() ?? key,
      depth: key.split('/').length - 1,
      count: counts.get(key) ?? 0,
    }));
  }, [rows]);

  const visible = useMemo(() => {
    const needle = query.trim().toLowerCase();

    return rows.filter((row) => {
      if (category && row.group !== category && !row.group?.startsWith(`${category}/`)) return false;
      if (!needle) return true;
      return (row.search ?? '').includes(needle) || loc(row.name).toLowerCase().includes(needle);
    });
  }, [rows, category, query, loc]);

  const current = visible.find((row) => row.key === selected) ?? visible[0];
  const rowHeight = rows.some((row) => row.sub) ? 52 : 38;
  const primary = actions[actions.length - 1];

  useEffect(() => {
    const node = listRef.current;
    if (!node) return;

    const observer = new ResizeObserver(() => setHeight(node.clientHeight || 300));
    observer.observe(node);
    return () => observer.disconnect();
  }, []);

  useEffect(() => {
    if (listRef.current) listRef.current.scrollTop = 0;
  }, [category, query]);

  const run = useCallback(
    (action: Action<R> | undefined, row: R | undefined) => {
      if (!action || (!action.free && !row)) return;
      action.run(row, values);
    },
    [values]
  );

  const pick = useCallback((row: R) => {
    setSelected(row.key);
    if (row.fields) setValues((current) => ({ ...current, ...row.fields }));
  }, []);

  const move = useCallback(
    (step: number) => {
      if (visible.length === 0) return;

      const at = Math.max(0, visible.indexOf(current as R));
      const next = Math.min(Math.max(at + step, 0), visible.length - 1);
      pick(visible[next]);

      const node = listRef.current;
      if (!node) return;

      const top = next * rowHeight;
      if (top < node.scrollTop) node.scrollTop = top;
      else if (top + rowHeight > node.scrollTop + node.clientHeight) node.scrollTop = top + rowHeight - node.clientHeight;
    },
    [visible, current, pick, rowHeight]
  );

  useEffect(() => {
    if (!active) return;

    const onKey = (event: KeyboardEvent) => {
      const from = event.target as HTMLElement | null;
      if (from?.dataset.field) return;

      if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
        event.preventDefault();
        move(event.key === 'ArrowDown' ? 1 : -1);
      } else if (event.key === 'Enter' && from?.tagName !== 'BUTTON') {
        event.preventDefault();
        run(primary, current);
      }
    };

    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [active, move, run, primary, current]);

  const onRowDown = (row: R) => {
    const now = Date.now();
    const again = clickRef.current.key === row.key && now - clickRef.current.at < DOUBLE_CLICK;
    clickRef.current = { key: row.key, at: now };

    pick(row);
    if (again) run(primary, row);
  };

  const first = Math.max(0, Math.floor(scroll / rowHeight) - OVERSCAN);
  const last = Math.min(visible.length, first + Math.ceil(height / rowHeight) + OVERSCAN * 2);


  return (
    <>
      <div className="flex min-h-0 flex-1">
        {categories.length > 0 && (
          <div className="flex w-48 shrink-0 flex-col border-r border-line pt-3">
            <div className="px-4 pb-2 text-[11px] font-semibold tracking-wider text-ink-faint uppercase">
              {t('common.categories')}
            </div>
            <div ref={categoryRef} className="min-h-0 flex-1 overflow-y-auto px-2 pb-2">
              {[{ key: '', label: '@common.all', depth: 0, count: rows.length }, ...categories].map((entry) => {
                const on = category === entry.key;

                return (
                  <button
                    key={entry.key || '*'}
                    onClick={() => setCategory(entry.key)}
                    className={`relative flex w-full items-center justify-between gap-2 rounded-lg py-1.5 pr-2.5 text-left text-[13px] outline-none transition-colors ${
                      on ? 'bg-raised font-medium text-ink' : 'text-ink-dim hover:bg-surface hover:text-ink'
                    }`}
                    style={{ paddingLeft: 12 + entry.depth * 12 }}
                  >
                    {on && <span className="absolute top-1.5 bottom-1.5 left-0 w-[3px] rounded-full bg-accent" />}
                    <span className="truncate">{loc(entry.label)}</span>
                    <span className="shrink-0 text-[11px] text-ink-faint tabular-nums">{entry.count}</span>
                  </button>
                );
              })}
            </div>
          </div>
        )}

        <div className="flex min-w-0 flex-1 flex-col gap-2.5 p-3">
          <Input
            icon={Search}
            value={query}
            placeholder={loc(search ?? '@common.search')}
            onChange={(event) => setQuery(event.target.value)}
            className="w-full shrink-0"
          />

          <div
            ref={listRef}
            onScroll={(event) => setScroll(event.currentTarget.scrollTop)}
            className="min-h-0 flex-1 overflow-y-auto"
          >
            {visible.length === 0 ? (
              <div className="py-12 text-center text-[13px] text-ink-faint">{loc(empty ?? '@common.nothing_found')}</div>
            ) : (
              <div className="relative" style={{ height: visible.length * rowHeight }}>
                <div style={{ transform: `translateY(${first * rowHeight}px)` }}>
                  {visible.slice(first, last).map((row) => {
                    const on = row.key === current?.key;

                    return (
                      <div key={row.key} className="py-[2px]" style={{ height: rowHeight }}>
                        <div
                          onMouseDown={() => onRowDown(row)}
                          className={`relative flex h-full items-center gap-3 rounded-lg px-3 transition-colors ${
                            on ? 'bg-brand/12' : 'hover:bg-surface'
                          }`}
                        >
                          {on && <span className="absolute top-2 bottom-2 left-0 w-[3px] rounded-full bg-accent" />}
                          <div className="min-w-0 flex-1">
                            <div className={`truncate text-[13px] ${on ? 'font-semibold text-ink' : 'text-ink'}`}>{loc(row.name)}</div>
                            {row.sub && <div className="truncate text-[11.5px] text-ink-faint">{loc(row.sub)}</div>}
                          </div>
                          {row.right && (
                            <span
                              className={`shrink-0 rounded-md px-2 py-0.5 text-[11.5px] tabular-nums ${
                                row.tone === 'ok'
                                  ? 'bg-good/12 text-good'
                                  : row.tone === 'muted'
                                    ? 'text-ink-faint'
                                    : 'bg-white/5 text-ink-dim'
                              }`}
                            >
                              {loc(row.right)}
                            </span>
                          )}
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      <div className="flex shrink-0 flex-wrap items-center gap-2.5 border-t border-line bg-black/15 px-4 py-3">
        {fields.map((field) => (
          <label key={field.id} className="flex items-center gap-2 text-[12px] text-ink-dim">
            {loc(field.label)}
            <Input
              data-field={field.id}
              value={values[field.id] ?? ''}
              maxLength={field.max}
              placeholder={field.placeholder ? loc(field.placeholder) : undefined}
              style={{ width: field.width ?? 90 }}
              onChange={(event) => {
                const raw = event.target.value;
                const value = field.text ? raw : raw.replace(/[^0-9.-]/g, '');
                setValues((currentValues) => ({ ...currentValues, [field.id]: value }));
              }}
              onKeyDown={(event) => {
                if (event.key === 'Enter') run(primary, current);
              }}
            />
          </label>
        ))}

        <div className="ml-auto flex flex-wrap justify-end gap-2">
          {actions.map((action, index) => {
            const label = typeof action.label === 'function' ? action.label(current) : action.label;

            return (
              <Button
                key={index}
                variant={action.variant}
                disabled={!action.free && !current}
                onClick={() => run(action, current)}
              >
                {loc(label)}
              </Button>
            );
          })}
        </div>
      </div>
    </>
  );
}
