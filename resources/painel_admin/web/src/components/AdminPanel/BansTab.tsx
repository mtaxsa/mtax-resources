import React, { useRef, useState } from 'react';
import { useWheelScroll } from '../../hooks/useWheelScroll';
import { AdminActions, BanRowAction } from './actions';
import type { Ban } from './types';
import { Button, Select } from './ui';

interface BansTabProps {
  bansSearch: string;
  onBansSearchChange: (value: string) => void;
  bans: Ban[];
  totalBans: number;
  selectedBanId: number | null;
  onSelectBan: (id: number) => void;
}

const SERIAL_MAX_CHARS = 16;

const SerialCell: React.FC<{ serial: string }> = ({ serial }) => {
  const [copied, setCopied] = useState(false);
  const truncated = serial.length > SERIAL_MAX_CHARS ? `${serial.slice(0, SERIAL_MAX_CHARS)}…` : serial;

  const handleCopy = async (e: React.MouseEvent) => {
    e.stopPropagation();
    try {
      await navigator.clipboard.writeText(serial);
      setCopied(true);
      setTimeout(() => setCopied(false), 1200);
    } catch {}
  };

  return (
    <div
      onClick={handleCopy}
      title={serial}
      className="group relative flex-[1.3] text-[#9aa1ad] text-[12px] font-mono whitespace-nowrap overflow-hidden text-ellipsis cursor-pointer"
    >
      {truncated}
      <span className="pointer-events-none absolute -top-[26px] left-0 hidden group-hover:flex items-center gap-1 bg-[#1c2027] text-[#e7e9ee] text-[10.5px] px-2 py-1 rounded-[5px] whitespace-nowrap z-10 shadow-md">
        {copied ? 'Copied!' : 'Copy'}
      </span>
    </div>
  );
};

export const BansTab: React.FC<BansTabProps> = ({ bansSearch, onBansSearchChange, bans, totalBans, selectedBanId, onSelectBan }) => {
  const [searchType, setSearchType] = useState<'Name' | 'IP' | 'Serial'>('Name');
  const hasSelection = selectedBanId !== null;
  const scrollRef = useRef<HTMLDivElement>(null);

  // CEF OSR drops wheel events after the native scrollbar thumb is dragged
  // (cef/cef#3567); route the wheel through JS so it never depends on that path.
  useWheelScroll(scrollRef);

  const runRowAction = (action: BanRowAction) => {
    if (selectedBanId === null) return;
    AdminActions.banRowAction(selectedBanId, action);
  };

  const runFieldBan = (field: 'ip' | 'serial') => {
    if (selectedBanId === null) return;
    AdminActions.banByField(selectedBanId, field);
  };

  return (
    <div className="flex-1 flex flex-col px-[28px] pt-2 pb-5 min-h-0">
      <div className="flex gap-2 items-center my-[10px] mb-[14px]">
        <input
          value={bansSearch}
          onChange={(e) => onBansSearchChange(e.target.value)}
          placeholder="Search by name, IP or serial…"
          className="flex-1 bg-[#333a47] border-none rounded-[8px] px-3 py-[9px] text-[#e7e9ee] text-[13px] font-sora outline-none placeholder:text-[#55606e]"
        />
        <Select value={searchType} onChange={(e) => setSearchType(e.target.value as 'Name' | 'IP' | 'Serial')} className="px-[10px] py-[9px] rounded-[8px]">
          <option>Name</option>
          <option>IP</option>
          <option>Serial</option>
        </Select>
        <Button variant="pill" onClick={() => AdminActions.searchBans(bansSearch, searchType)}>
          Search…
        </Button>
      </div>

      <div className="flex px-[10px] py-2 text-[#6b7280] text-[11px] font-bold tracking-[0.6px] uppercase border-b border-white/[0.06]">
        <div className="flex-[1.4]">Name</div>
        <div className="flex-[1.1]">IP</div>
        <div className="flex-[1.3]">Serial</div>
        <div className="flex-1">By</div>
        <div className="flex-1">Date</div>
      </div>

      <div ref={scrollRef} className="op-scroll flex-1 overflow-y-auto min-h-0">
        {bans.map((b) => {
          const selected = selectedBanId === b.id;
          return (
            <div
              key={b.id}
              onClick={() => onSelectBan(b.id)}
              className={`flex px-[10px] py-[9px] rounded-[7px] cursor-pointer ${selected ? 'bg-[rgba(31,157,111,0.14)]' : 'bg-transparent'}`}
            >
              <div className="flex-[1.4] text-[#d7dae1] text-[12.5px] whitespace-nowrap overflow-hidden text-ellipsis">{b.name}</div>
              <div className="flex-[1.1] text-[#9aa1ad] text-[12px] font-mono">{b.ip}</div>
              <SerialCell serial={b.serial} />
              <div className="flex-1 text-[#9aa1ad] text-[12px]">{b.by}</div>
              <div className="flex-1 text-[#9aa1ad] text-[12px] font-mono">{b.date}</div>
            </div>
          );
        })}
      </div>

      <div className="flex items-center gap-[14px] pt-3 px-1 border-t border-white/[0.06] mt-[10px]">
        <div className="flex gap-[6px]">
          <Button variant="pill" disabled={!hasSelection} className="disabled:opacity-40 disabled:pointer-events-none" onClick={() => runRowAction('details')}>
            Details
          </Button>
          <Button variant="pill" disabled={!hasSelection} className="disabled:opacity-40 disabled:pointer-events-none" onClick={() => runRowAction('unban')}>
            Unban
          </Button>
          <Button variant="pill" disabled={!hasSelection} className="disabled:opacity-40 disabled:pointer-events-none" onClick={() => runRowAction('unbanIp')}>
            Unban IP
          </Button>
          <Button variant="pill" disabled={!hasSelection} className="disabled:opacity-40 disabled:pointer-events-none" onClick={() => runRowAction('unbanSerial')}>
            Unban Serial
          </Button>
        </div>
        <div className="w-px h-[22px] bg-white/[0.08]" />
        <div className="flex gap-[6px]">
          <Button variant="pillDanger" disabled={!hasSelection} className="disabled:opacity-40 disabled:pointer-events-none" onClick={() => runFieldBan('ip')}>
            Ban IP
          </Button>
          <Button variant="pillDanger" disabled={!hasSelection} className="disabled:opacity-40 disabled:pointer-events-none" onClick={() => runFieldBan('serial')}>
            Ban Serial
          </Button>
        </div>
        <div className="flex-1" />
        <Button variant="pill" onClick={() => AdminActions.refreshBans()}>
          Refresh
        </Button>
      </div>

      <div className="flex items-center justify-between pt-[10px] px-1 text-[#6b7280] text-[12px]">
        <div>
          Showing {bans.length} / {totalBans} bans
        </div>
      </div>
    </div>
  );
};
