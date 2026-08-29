import React, { useEffect, useRef } from 'react';
import type { Suggestion } from './types';

interface Props {
  items: Suggestion[];
  index: number;
  onPick: (item: Suggestion) => void;
}

export const Suggestions: React.FC<Props> = ({ items, index, onPick }) => {
  const listRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const row = listRef.current?.children[index] as HTMLElement | undefined;
    row?.scrollIntoView({ block: 'nearest' });
  }, [index, items.length]);

  useEffect(() => {
    const onWheel = (event: WheelEvent) => {
      const list = listRef.current;
      if (!list) return;

      const box = list.getBoundingClientRect();
      const inside =
        event.clientX >= box.left &&
        event.clientX <= box.right &&
        event.clientY >= box.top &&
        event.clientY <= box.bottom;
      if (!inside) return;

      event.preventDefault();
      list.scrollTop += event.deltaY;
    };

    window.addEventListener('wheel', onWheel, { passive: false });
    return () => window.removeEventListener('wheel', onWheel);
  }, []);

  if (items.length === 0) return null;

  return (
    <div className="interactive mb-2 overflow-hidden rounded-xl border border-line bg-panel-solid shadow-[0_10px_28px_rgb(0_0_0/0.45)]">
      <div ref={listRef} className="max-h-[196px] overflow-y-auto py-1">
        {items.map((item, position) => (
          <button
            key={item.name}
            onMouseDown={(event) => event.preventDefault()}
            onClick={() => onPick(item)}
            className="flex w-full items-baseline gap-2 px-3 py-1.5 text-left outline-none"
            style={{ background: position === index ? 'var(--color-raised)' : 'transparent' }}
          >
            <span className="text-[13px] font-semibold text-ink">/{item.name}</span>
            <span className="text-[12px] text-ink-faint">{item.params}</span>
            <span className="flex-1" />
            <span className="truncate text-[11px] text-ink-faint">{item.help}</span>
          </button>
        ))}
      </div>

      <div className="flex items-center gap-3 border-t border-line px-3 py-1.5 text-[10px] text-ink-faint">
        <span>
          <b className="text-ink-dim">↑ ↓</b> browse
        </span>
        <span>
          <b className="text-ink-dim">Enter</b> pick
        </span>
        <span>
          <b className="text-ink-dim">Tab</b> switch chat
        </span>
      </div>
    </div>
  );
};
