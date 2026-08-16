import React, { useEffect, useRef, useState } from 'react';
import { useWheelScroll } from '../../hooks/useWheelScroll';
import { AdminActions, VehicleCustomizeAction } from './actions';
import type { Player, VehicleCustomization } from './types';
import { Button, Select } from './ui';

interface VehicleCustomizeModalProps {
  player: Player;
  onClose: () => void;
  scale: number;
}

const stopClick = (e: React.MouseEvent) => e.stopPropagation();

const clamp255 = (n: number) => Math.max(0, Math.min(255, Math.round(n)));

const rgbToHex = (r: number, g: number, b: number) =>
  '#' + [r, g, b].map((n) => clamp255(n).toString(16).padStart(2, '0')).join('');

const hexToRgb = (hex: string): [number, number, number] => {
  const n = parseInt(hex.slice(1), 16) || 0;
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
};

export const VehicleCustomizeModal: React.FC<VehicleCustomizeModalProps> = ({ player, onClose, scale }) => {
  const [data, setData] = useState<VehicleCustomization | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [pendingUpgrades, setPendingUpgrades] = useState<Record<number, number>>({});
  const [colorHexes, setColorHexes] = useState<string[]>(['#000000', '#000000', '#000000', '#000000']);
  const [paintjob, setPaintjob] = useState(3);
  const [plate, setPlate] = useState('');
  const [headlightHex, setHeadlightHex] = useState('#ffffff');
  const scrollRef = useRef<HTMLDivElement>(null);

  // CEF OSR drops wheel events after the native scrollbar thumb is dragged
  // (cef/cef#3567); route the wheel through JS so it never depends on that path.
  useWheelScroll(scrollRef);

  const applySnapshot = (snap: VehicleCustomization) => {
    if (!snap || !snap.ok) {
      setError((snap && snap.message) || 'Failed to load vehicle customization.');
      return;
    }
    setError(null);
    setNotice(snap.message || null);
    setData(snap);
    const upgrades: Record<number, number> = {};
    snap.slots.forEach((s) => {
      upgrades[s.slot] = s.current;
    });
    setPendingUpgrades(upgrades);
    setColorHexes([0, 3, 6, 9].map((i) => rgbToHex(snap.colors[i], snap.colors[i + 1], snap.colors[i + 2])));
    setPaintjob(snap.paintjob);
    setPlate(snap.plate);
    setHeadlightHex(rgbToHex(snap.headlight.r, snap.headlight.g, snap.headlight.b));
  };

  useEffect(() => {
    AdminActions.getVehicleCustomization(player.id)
      .then((res) => applySnapshot(res))
      .catch(() => setError('Failed to communicate with the server.'));
    // Only re-fetch if the target player itself changes — not on every local
    // pending-selection edit.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [player.id]);

  const runAction = (action: VehicleCustomizeAction, payload?: Record<string, unknown>) => {
    AdminActions.vehicleCustomizeAction(player.id, action, payload)
      .then((res) => applySnapshot(res))
      .catch(() => setError('Failed to communicate with the server.'));
  };

  return (
    <div onClick={onClose} className="fixed inset-0 bg-black/55 flex items-center justify-center z-50">
      <div onClick={stopClick} className="shrink-0" style={{ transform: `scale(${scale})` }}>
        <div className="w-[680px] max-w-[92vw] h-[540px] rounded-2xl bg-[#262c37] border border-white/[0.07] shadow-[0_40px_90px_-20px_rgba(0,0,0,0.75)] flex flex-col overflow-hidden relative">
          <div className="text-center py-[14px] pb-[14px] border-b border-white/[0.06] text-[#f0f2f6] text-[15px] font-bold">
            Vehicle Customization{data ? ` — ${data.vehicleName}` : ''}
          </div>

          {error && (
            <div className="flex-1 flex items-center justify-center text-[#f2637d] text-[13px] px-6 text-center">{error}</div>
          )}

          {!error && notice && (
            <div className="text-[#f2a13d] text-[12px] px-4 py-2 text-center border-b border-white/[0.06]">{notice}</div>
          )}

          {!error && !data && <div className="flex-1 flex items-center justify-center text-[#767d89] text-[13px]">Loading…</div>}

          {!error && data && (
            <div className="flex-1 flex min-h-0">
              <div
                ref={scrollRef}
                className="op-scroll flex-1 overflow-y-auto pt-[14px] pr-[10px] pb-[14px] pl-[18px] border-r border-white/[0.06]"
              >
                <div className="text-[#6b7280] text-[11px] font-bold tracking-[0.8px] uppercase mb-2">Upgrades</div>
                {data.slots.length === 0 && (
                  <div className="text-[#565c66] text-[12px]">This vehicle has no upgrade slots.</div>
                )}
                {data.slots.map((slot) => (
                  <div key={slot.slot} className="flex items-center justify-between gap-2 py-[5px]">
                    <div className="text-[#c7cbd3] text-[12px] flex-shrink-0">
                      {slot.name}
                      <span className="text-[#565c66] font-mono"> (slot {slot.slot})</span>
                    </div>
                    <Select
                      value={pendingUpgrades[slot.slot] ?? 0}
                      onChange={(e) => setPendingUpgrades((prev) => ({ ...prev, [slot.slot]: Number(e.target.value) }))}
                      className="min-w-[150px]"
                    >
                      <option value={0}>None</option>
                      {slot.options.map((opt) => (
                        <option key={opt.id} value={opt.id}>
                          #{opt.id} — {opt.name}
                        </option>
                      ))}
                    </Select>
                  </div>
                ))}
              </div>

              <div className="w-[260px] flex-shrink-0 p-4 flex flex-col gap-3 overflow-y-auto op-scroll">
                <div>
                  <div className="text-[#6b7280] text-[11px] font-bold tracking-[0.8px] uppercase mb-2">Paint job</div>
                  <div className="flex gap-[6px]">
                    <Select value={paintjob} onChange={(e) => setPaintjob(Number(e.target.value))}>
                      <option value={0}>Paintjob 1</option>
                      <option value={1}>Paintjob 2</option>
                      <option value={2}>Paintjob 3</option>
                      <option value={3}>None</option>
                    </Select>
                    <Button variant="pill" onClick={() => runAction('setPaintjob', { paintjob })}>
                      Set
                    </Button>
                  </div>
                </div>

                <div>
                  <div className="text-[#6b7280] text-[11px] font-bold tracking-[0.8px] uppercase mb-2">Vehicle color</div>
                  <div className="grid grid-cols-2 gap-2">
                    {colorHexes.map((hex, i) => (
                      <div key={i} className="flex items-center gap-[6px]">
                        <input
                          type="color"
                          value={hex}
                          onChange={(e) => setColorHexes((prev) => prev.map((h, idx) => (idx === i ? e.target.value : h)))}
                          className="w-[26px] h-[26px] rounded-[6px] border-none bg-transparent cursor-pointer p-0"
                        />
                        <div className="text-[#9aa1ad] text-[11px] font-mono">Color {i + 1}</div>
                      </div>
                    ))}
                  </div>
                  <Button
                    variant="pill"
                    className="mt-2 w-full"
                    onClick={() => runAction('setColors', { colors: colorHexes.flatMap((hex) => hexToRgb(hex)) })}
                  >
                    Set colors
                  </Button>
                </div>

                <div>
                  <div className="text-[#6b7280] text-[11px] font-bold tracking-[0.8px] uppercase mb-2">Lights color</div>
                  <div className="flex items-center gap-[6px]">
                    <input
                      type="color"
                      value={headlightHex}
                      onChange={(e) => setHeadlightHex(e.target.value)}
                      className="w-[26px] h-[26px] rounded-[6px] border-none bg-transparent cursor-pointer p-0"
                    />
                    <Button
                      variant="pill"
                      onClick={() => {
                        const [r, g, b] = hexToRgb(headlightHex);
                        runAction('setHeadlightColor', { r, g, b });
                      }}
                    >
                      Set
                    </Button>
                  </div>
                </div>

                <div>
                  <div className="text-[#6b7280] text-[11px] font-bold tracking-[0.8px] uppercase mb-2">License plate</div>
                  <div className="flex gap-[6px]">
                    <input
                      value={plate}
                      maxLength={8}
                      onChange={(e) => setPlate(e.target.value.toUpperCase())}
                      className="flex-1 min-w-0 bg-[#333a47] border-none rounded-[7px] px-[10px] py-[7px] text-[#e7e9ee] text-[12.5px] font-mono outline-none"
                    />
                    <Button variant="pill" onClick={() => runAction('setPlate', { plate })}>
                      Set
                    </Button>
                  </div>
                </div>
              </div>
            </div>
          )}

          <div className="flex items-center justify-between px-4 py-3 border-t border-white/[0.06]">
            <div className="flex gap-[6px]">
              {!error && data && (
                <>
                  <Button variant="pill" onClick={() => runAction('upgradeAll')}>
                    Upgrade All
                  </Button>
                  <Button variant="pillDanger" onClick={() => runAction('removeAll')}>
                    Remove All
                  </Button>
                  <Button variant="pill" onClick={() => runAction('setUpgrades', { upgrades: pendingUpgrades })}>
                    Upgrade Selected
                  </Button>
                </>
              )}
            </div>
            <Button variant="pill" onClick={onClose}>
              Close
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
};
