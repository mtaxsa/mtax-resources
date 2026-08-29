import React, { useState } from 'react';
import { EMOJI_GROUPS } from './emoji';
import { Popover } from './Popover';
import { Sticker } from './Sticker';

export type PickerMode = 'emoji' | 'stickers';

interface Props {
  stickers: string[];
  mode: PickerMode;
  setMode: (mode: PickerMode) => void;
  onEmoji: (char: string) => void;
  onSticker: (id: string) => void;
}

export const PickerPanel: React.FC<Props> = ({ stickers, mode, setMode, onEmoji, onSticker }) => {
  const [group, setGroup] = useState(0);

  return (
    <Popover width={336}>
      <div className="flex shrink-0 border-b border-line">
        {(['emoji', 'stickers'] as PickerMode[]).map((entry) => (
          <button
            key={entry}
            onClick={() => setMode(entry)}
            className="flex-1 px-3 py-2 text-[11px] font-bold tracking-wide uppercase outline-none"
            style={{
              color: mode === entry ? 'var(--color-ink)' : 'var(--color-ink-faint)',
              borderBottom: `2px solid ${mode === entry ? 'var(--color-brand)' : 'transparent'}`,
            }}
          >
            {entry}
          </button>
        ))}
      </div>

      {mode === 'emoji' ? (
        <>
          <div className="flex shrink-0 gap-0.5 border-b border-line px-1.5 py-1.5">
            {EMOJI_GROUPS.map((entry, index) => (
              <button
                key={entry.key}
                title={entry.label}
                onClick={() => setGroup(index)}
                className="flex h-7 flex-1 items-center justify-center rounded-md text-[15px] outline-none hover:bg-raised"
                style={{ background: group === index ? 'var(--color-raised)' : 'transparent' }}
              >
                {entry.icon}
              </button>
            ))}
          </div>

          <div className="grid max-h-[214px] min-h-0 flex-1 grid-cols-9 content-start gap-0.5 overflow-y-auto p-1.5">
            {EMOJI_GROUPS[group].chars.map((char, index) => (
              <button
                key={`${char}-${index}`}
                onClick={() => onEmoji(char)}
                className="flex h-8 items-center justify-center rounded-md text-[18px] leading-none outline-none hover:bg-raised"
              >
                {char}
              </button>
            ))}
          </div>
        </>
      ) : (
        <div className="grid max-h-[256px] min-h-0 flex-1 grid-cols-5 content-start gap-1 overflow-y-auto p-2">
          {stickers.length === 0 && (
            <div className="col-span-5 py-6 text-center text-[12px] text-ink-faint">
              No stickers configured
            </div>
          )}
          {stickers.map((id) => (
            <button
              key={id}
              onClick={() => onSticker(id)}
              className="flex h-14 items-center justify-center rounded-lg outline-none hover:bg-raised"
            >
              <Sticker id={id} size={40} />
            </button>
          ))}
        </div>
      )}
    </Popover>
  );
};
