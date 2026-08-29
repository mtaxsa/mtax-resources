import React, { useEffect, useRef, useState } from 'react';
import { PickerPanel, type PickerMode } from './PickerPanel';
import { SettingsPanel } from './SettingsPanel';
import type { ChatType, Corner, Settings } from './types';

interface Props {
  types: Record<string, ChatType>;
  tabs: string[];
  tab: string;
  setTab: (tab: string) => void;
  text: string;
  setText: (text: string) => void;
  target: string;
  setTarget: (target: string) => void;
  maxLength: number;
  stickers: string[];
  inputRef: React.RefObject<HTMLInputElement>;
  onKeyDown: (event: React.KeyboardEvent<HTMLInputElement>) => void;
  onSend: () => void;
  onSticker: (id: string) => void;
  onDice: () => void;
  onDragStart: (event: React.MouseEvent) => void;
  colorOf: (kind: string) => string;
  settings: Settings;
  timestamps: boolean;
  patch: (next: Partial<Settings>) => void;
  setColor: (kind: string, color: string | null) => void;
  onCorner: (corner: Corner) => void;
  onReset: () => void;
}

type Panel = 'none' | 'picker' | 'settings';

const IconButton: React.FC<{
  title: string;
  active?: boolean;
  onClick: () => void;
  children: React.ReactNode;
}> = ({ title, active, onClick, children }) => (
  <button
    title={title}
    onMouseDown={(event) => event.preventDefault()}
    onClick={onClick}
    className="flex h-7 w-7 shrink-0 items-center justify-center rounded-md text-[15px] leading-none outline-none transition-colors hover:bg-raised"
    style={{ background: active ? 'var(--color-raised)' : 'transparent' }}
  >
    {children}
  </button>
);

const SendIcon = () => (
  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" aria-hidden>
    <path d="M3.4 20.4 21 12 3.4 3.6 3.4 10l12 2-12 2z" fill="currentColor" />
  </svg>
);

const GearIcon = () => (
  <svg width="15" height="15" viewBox="0 0 24 24" fill="none" aria-hidden>
    <path
      d="M12 15.5a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7Z"
      stroke="currentColor"
      strokeWidth="1.8"
    />
    <path
      d="M19.4 15a1.6 1.6 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.6 1.6 0 0 0-1.8-.3 1.6 1.6 0 0 0-1 1.5v.2a2 2 0 1 1-4 0v-.1a1.6 1.6 0 0 0-1-1.5 1.6 1.6 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.6 1.6 0 0 0 .3-1.8 1.6 1.6 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.6 1.6 0 0 0 1.5-1 1.6 1.6 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.6 1.6 0 0 0 1.8.3H9a1.6 1.6 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.6 1.6 0 0 0 1 1.5 1.6 1.6 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.6 1.6 0 0 0-.3 1.8V9a1.6 1.6 0 0 0 1.5 1h.2a2 2 0 1 1 0 4h-.1a1.6 1.6 0 0 0-1.5 1Z"
      stroke="currentColor"
      strokeWidth="1.6"
    />
  </svg>
);

const StickerIcon = () => (
  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" aria-hidden>
    <path
      d="M14 3H7a4 4 0 0 0-4 4v10a4 4 0 0 0 4 4h4l10-10V7a4 4 0 0 0-4-4h-3Z"
      stroke="currentColor"
      strokeWidth="1.7"
      strokeLinejoin="round"
    />
    <path d="M21 11h-4a4 4 0 0 0-4 4v4" stroke="currentColor" strokeWidth="1.7" strokeLinejoin="round" />
  </svg>
);

export const Composer: React.FC<Props> = (props) => {
  const {
    types,
    tabs,
    tab,
    setTab,
    text,
    setText,
    target,
    setTarget,
    maxLength,
    stickers,
    inputRef,
    onKeyDown,
    onSend,
    onSticker,
    onDice,
    onDragStart,
    colorOf,
    settings,
    timestamps,
    patch,
    setColor,
    onCorner,
    onReset,
  } = props;

  const [panel, setPanel] = useState<Panel>('none');
  const [pickerMode, setPickerMode] = useState<PickerMode>('emoji');
  const shell = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (panel === 'none') return;

    const away = (event: MouseEvent) => {
      if (shell.current && !shell.current.contains(event.target as Node)) setPanel('none');
    };

    window.addEventListener('mousedown', away);
    return () => window.removeEventListener('mousedown', away);
  }, [panel]);

  const type = types[tab];
  const color = colorOf(tab);
  const isPm = tab === 'pm';

  const insert = (chunk: string) => {
    setText((text + chunk).slice(0, maxLength));
    inputRef.current?.focus();
  };

  const toggle = (next: Panel) => setPanel((current) => (current === next ? 'none' : next));

  const openPicker = (next: PickerMode) => {
    setPickerMode(next);
    setPanel((current) => (current === 'picker' && pickerMode === next ? 'none' : 'picker'));
  };

  return (
    <div ref={shell} className="interactive relative mt-2">
      <div className="flex items-center gap-2">
        <div className="flex h-11 min-w-0 flex-1 items-center gap-2 rounded-xl border border-line bg-panel-solid px-2">
          <span
            onMouseDown={onDragStart}
            title="Drag to move the chat"
            className="shrink-0 cursor-grab rounded px-1.5 py-1 text-[10px] leading-none font-extrabold tracking-wide text-black active:cursor-grabbing"
            style={{ background: color }}
          >
            {type?.label ?? tab.toUpperCase()}
          </span>

          {isPm && (
            <input
              value={target}
              onChange={(event) => setTarget(event.target.value.replace(/\D/g, '').slice(0, 4))}
              placeholder="id"
              className="h-7 w-12 shrink-0 rounded-md border border-line bg-raised px-1.5 text-center text-[12px] font-semibold text-ink outline-none placeholder:text-ink-faint"
            />
          )}

          <input
            ref={inputRef}
            value={text}
            maxLength={maxLength}
            onChange={(event) => setText(event.target.value)}
            onKeyDown={onKeyDown}
            placeholder={isPm ? 'Private message…' : 'Enter message…'}
            className="h-full min-w-0 flex-1 bg-transparent text-[13px] text-ink outline-none placeholder:text-ink-faint"
          />

          {text.length > maxLength - 30 && (
            <span className="shrink-0 text-[10px] font-semibold text-ink-faint">
              {maxLength - text.length}
            </span>
          )}

          <IconButton
            title="Emoji"
            active={panel === 'picker' && pickerMode === 'emoji'}
            onClick={() => openPicker('emoji')}
          >
            <span className="text-[15px]">🙂</span>
          </IconButton>

          <IconButton
            title="Stickers"
            active={panel === 'picker' && pickerMode === 'stickers'}
            onClick={() => openPicker('stickers')}
          >
            <StickerIcon />
          </IconButton>

          <IconButton title="Roll a die" onClick={onDice}>
            <span className="text-[15px]">🎲</span>
          </IconButton>
        </div>

        <button
          title="Send"
          onMouseDown={(event) => event.preventDefault()}
          onClick={onSend}
          className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl text-white outline-none transition-opacity hover:opacity-90"
          style={{ background: 'var(--color-brand)' }}
        >
          <SendIcon />
        </button>
      </div>

      <div className="mt-2 flex items-center gap-1.5">
        {tabs.map((kind) => {
          const entry = types[kind];
          if (!entry) return null;
          const active = kind === tab;

          return (
            <button
              key={kind}
              onMouseDown={(event) => event.preventDefault()}
              onClick={() => {
                setTab(kind);
                inputRef.current?.focus();
              }}
              className="rounded-lg px-2.5 py-1.5 text-[11px] font-bold tracking-wide outline-none transition-colors"
              style={{
                background: active ? 'var(--color-raised)' : 'var(--color-panel)',
                color: active ? colorOf(kind) : 'var(--color-ink-faint)',
                border: `1px solid ${active ? colorOf(kind) : 'var(--color-line)'}`,
              }}
            >
              {entry.label}
            </button>
          );
        })}

        <span className="flex-1" />

        <button
          title="Settings"
          onMouseDown={(event) => event.preventDefault()}
          onClick={() => toggle('settings')}
          className="flex h-[30px] w-[30px] items-center justify-center rounded-lg border border-line bg-panel text-ink-dim outline-none hover:text-ink"
          style={{ background: panel === 'settings' ? 'var(--color-raised)' : undefined }}
        >
          <GearIcon />
        </button>
      </div>

      {panel === 'picker' && (
        <PickerPanel
          stickers={stickers}
          mode={pickerMode}
          setMode={setPickerMode}
          onEmoji={insert}
          onSticker={(id) => {
            onSticker(id);
            setPanel('none');
          }}
        />
      )}

      {panel === 'settings' && (
        <SettingsPanel
          settings={settings}
          types={types}
          tabs={tabs}
          timestamps={timestamps}
          patch={patch}
          setColor={setColor}
          onCorner={(corner) => {
            onCorner(corner);
            setPanel('none');
          }}
          onReset={onReset}
        />
      )}
    </div>
  );
};
