import React from 'react';
import { Sticker } from './Sticker';
import type { ChatType, HistoryRow } from './types';

interface Props {
  row: HistoryRow;
  type: ChatType;
  color: string;
  timestamps: boolean;
  fresh: boolean;
  stale: boolean;
}

const Body: React.FC<{ row: HistoryRow; color: string }> = ({ row, color }) => {
  if (row.segments && row.segments.length > 0) {
    return (
      <span>
        {row.segments.map((run, index) => (
          <span key={index} style={{ color: run.color }}>
            {run.text}
          </span>
        ))}
      </span>
    );
  }

  return <span style={{ color: row.kind === 'system' ? color : undefined }}>{row.text}</span>;
};

export const MessageRow: React.FC<Props> = ({ row, type, color, timestamps, fresh, stale }) => {
  const plain = type.form === 'plain';

  return (
    <div
      className={`overflow-hidden rounded-lg bg-panel ${
        fresh ? 'animate-[chatRowIn_0.28s_cubic-bezier(0.16,1,0.3,1)]' : ''
      }`}
      style={{
        borderLeft: `3px solid ${color}`,
        opacity: stale ? 0.45 : 1,
        transition: 'opacity 0.4s ease',
      }}
    >
      {!plain && (
        <div className="flex items-center gap-2 px-2.5 pt-2">
          <span
            className="rounded px-1.5 py-0.5 text-[10px] leading-none font-extrabold tracking-wide text-black"
            style={{ background: color }}
          >
            {type.label}
          </span>

          {row.pid !== undefined && (
            <span className="rounded bg-raised px-1.5 py-0.5 text-[10px] leading-none font-semibold text-ink-dim">
              ID:{row.pid}
            </span>
          )}

          {row.note && (
            <span className="shrink-0 text-[11px] font-medium text-ink-faint">{row.note}</span>
          )}

          <span className="truncate text-[13px] font-semibold text-ink">{row.name}</span>

          <span className="flex-1" />

          {timestamps && row.time && (
            <span className="shrink-0 text-[11px] font-medium text-ink-faint">{row.time}</span>
          )}
        </div>
      )}

      {(row.text !== '' || plain) && (
        <div
          className={`flex items-start gap-2 px-2.5 text-[13px] leading-snug break-words text-ink ${
            plain ? 'py-2' : 'pt-1 pb-2'
          }`}
        >
          {plain && (
            <span
              className="mt-0.5 shrink-0 text-[10px] leading-none font-extrabold tracking-wide"
              style={{ color }}
            >
              {type.label}
            </span>
          )}

          <span className="min-w-0 flex-1">
            <Body row={row} color={color} />
          </span>

          {plain && timestamps && row.time && (
            <span className="shrink-0 text-[11px] font-medium text-ink-faint">{row.time}</span>
          )}
        </div>
      )}

      {row.sticker && (
        <div className={`px-2.5 pb-2 ${row.text === '' && !plain ? 'pt-1' : ''}`}>
          <Sticker id={row.sticker} size={64} />
        </div>
      )}
    </div>
  );
};
