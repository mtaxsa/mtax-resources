import React, { useRef, useState } from 'react';
import { useWheelScroll } from '../../hooks/useWheelScroll';
import { AdminActions, ModerationAction, PlayerStat, VehicleMaintenanceAction } from './actions';
import {
  DANGER_MOD_LABELS,
  DANGER_VEHICLE_LABELS,
  INTERIOR_LOCATIONS,
  MOD_LABELS,
  SET_LABELS,
  VEHICLE_LABELS,
  VEHICLE_MODEL_IDS,
  WEAPON_IDS,
} from './data';
import type { Player, TogglesState } from './types';
import { Button, FieldRow, SectionLabel, Select, Toggle } from './ui';

export interface PromptRequest {
  title: string;
  label: string;
  confirmLabel?: string;
  defaultValue?: string;
  onConfirm: (value: string) => void;
}

interface PlayersTabProps {
  playerOptions: Player[];
  player: Player;
  onSelectPlayer: (id: number) => void;
  toggles: TogglesState;
  onToggleChange: (key: keyof TogglesState) => void;
  onRequestInput: (request: PromptRequest) => void;
  onOpenVehicleCustomize: () => void;
}

const TOGGLE_DEFS: { key: keyof TogglesState; label: string }[] = [
  { key: 'hideSensitive', label: 'Hide sensitive data' },
];

const MODERATION_ACTION_BY_LABEL: Record<string, ModerationAction> = {
  Kick: 'kick',
  Ban: 'ban',
  Mute: 'mute',
  Freeze: 'freeze',
};

const VEHICLE_ACTION_BY_LABEL: Record<string, VehicleMaintenanceAction> = {
  Repair: 'repair',
  Explode: 'explode',
  Destroy: 'destroy',
};

const SET_BUTTON_CONFIG: Record<string, { stat: PlayerStat; title: string; label: string }> = {
  Health: { stat: 'health', title: 'Set Health', label: 'New health (0-100):' },
  Armour: { stat: 'armour', title: 'Set Armour', label: 'New armour (0-100):' },
  Skin: { stat: 'skin', title: 'Set Skin', label: 'New skin ID:' },
  Money: { stat: 'money', title: 'Set Money', label: 'New money amount:' },
};

export const PlayersTab: React.FC<PlayersTabProps> = ({
  playerOptions,
  player,
  onSelectPlayer,
  toggles,
  onToggleChange,
  onRequestInput,
  onOpenVehicleCustomize,
}) => {
  const [weaponId, setWeaponId] = useState(WEAPON_IDS['AK-47']);
  const [vehicleModelId, setVehicleModelId] = useState(VEHICLE_MODEL_IDS.Infernus);
  const [slapAmount, setSlapAmount] = useState(20);
  const scrollRef = useRef<HTMLDivElement>(null);

  // CEF OSR drops wheel events after the native scrollbar thumb is dragged
  // (cef/cef#3567); route the wheel through JS so it never depends on that path.
  useWheelScroll(scrollRef);

  const maskSensitive = (value: string) => '•'.repeat(Math.max(6, value.length));

  const playerFields = [
    { label: 'IP', value: toggles.hideSensitive ? maskSensitive(player.ip) : player.ip },
    { label: 'Serial', value: toggles.hideSensitive ? maskSensitive(player.serial) : player.serial },
    { label: 'Game version', value: player.version },
    { label: 'Account name', value: toggles.hideSensitive ? maskSensitive(player.accountName) : player.accountName },
    { label: 'Groups', value: player.groups.length > 0 ? player.groups.join(', ') : 'None' },
    { label: 'AC Detected', value: player.acDetected },
  ];

  const gameFields = [
    { label: 'Skin', value: player.skin },
    { label: 'Weapon', value: player.weapon },
    { label: 'Ping', value: `${player.ping}` },
    { label: 'Money', value: `$${player.money}` },
    { label: 'Area', value: player.area },
    { label: 'Position', value: player.pos },
    { label: 'Dimension', value: `${player.dimension}` },
    { label: 'Interior', value: `${player.interior}` },
  ];

  const vehicleFields = [
    { label: 'Vehicle', value: player.vehicle },
    { label: 'Vehicle health', value: `${player.vehicleHealth}%` },
  ];

  const handleSetButton = (label: string) => {
    const config = SET_BUTTON_CONFIG[label];
    onRequestInput({
      title: config.title,
      label: config.label,
      onConfirm: (value) => {
        if (value.trim()) AdminActions.setPlayerStat(player.id, config.stat, value.trim());
      },
    });
  };

  return (
    <div ref={scrollRef} className="op-scroll flex-1 overflow-y-auto px-[28px] pt-2 pb-[28px]">
      <SectionLabel first>Player</SectionLabel>
      <div className="flex items-center justify-between py-3 border-b border-white/5">
        <div className="text-[#d7dae1] text-[13.5px]">Select player</div>
        <div className="flex items-center gap-[10px]">
          <div className="w-[26px] h-[26px] rounded-full bg-[linear-gradient(135deg,#7fe0b8,#1f9d6f)] flex-shrink-0" />
          <Select value={player.id} onChange={(e) => onSelectPlayer(Number(e.target.value))} className="pr-[30px] pl-3">
            {playerOptions.map((p) => (
              <option key={p.id} value={p.id}>
                {p.name}
              </option>
            ))}
          </Select>
        </div>
      </div>

      {playerFields.map((f) => (
        <FieldRow key={f.label} {...f} />
      ))}

      <SectionLabel>Game</SectionLabel>

      <div className="flex items-center justify-between py-3 border-b border-white/5">
        <div className="text-[#d7dae1] text-[13.5px]">Health</div>
        <div className="flex items-center gap-[10px] w-[220px]">
          <div className="flex-1 h-[6px] rounded-[3px] bg-[#333a47] overflow-hidden">
            <div className="h-full rounded-[3px] bg-[#5fd88a]" style={{ width: `${player.health}%` }} />
          </div>
          <div className="text-[#9aa1ad] text-[12px] font-mono w-[34px] text-right">{player.health}%</div>
        </div>
      </div>

      <div className="flex items-center justify-between py-3 border-b border-white/5">
        <div className="text-[#d7dae1] text-[13.5px]">Armour</div>
        <div className="flex items-center gap-[10px] w-[220px]">
          <div className="flex-1 h-[6px] rounded-[3px] bg-[#333a47] overflow-hidden">
            <div className="h-full rounded-[3px] bg-[#1f9d6f]" style={{ width: `${player.armour}%` }} />
          </div>
          <div className="text-[#9aa1ad] text-[12px] font-mono w-[34px] text-right">{player.armour}%</div>
        </div>
      </div>

      {gameFields.map((f) => (
        <FieldRow key={f.label} {...f} />
      ))}

      <SectionLabel>Vehicle</SectionLabel>
      {vehicleFields.map((f) => (
        <FieldRow key={f.label} {...f} />
      ))}

      <SectionLabel>Moderation</SectionLabel>
      <div className="flex items-center justify-between gap-4 py-3 border-b border-white/5">
        <div className="text-[#d7dae1] text-[13.5px] flex-shrink-0">Punish</div>
        <div className="flex gap-[6px] flex-wrap justify-end bg-[#333a47] p-1 rounded-[9px]">
          {MOD_LABELS.map((label) => (
            <Button
              key={label}
              variant={DANGER_MOD_LABELS.includes(label) ? 'pillDanger' : 'pill'}
              onClick={() => AdminActions.moderatePlayer(player.id, MODERATION_ACTION_BY_LABEL[label])}
            >
              {label === 'Freeze' && player.frozen
                ? 'Unfreeze'
                : label === 'Mute' && player.muted
                ? 'Unmute'
                : label}
            </Button>
          ))}
        </div>
      </div>

      <div className="flex items-center justify-between gap-4 py-3 border-b border-white/5">
        <div className="text-[#d7dae1] text-[13.5px] flex-shrink-0">Spectate / Light punish</div>
        <div className="flex gap-[6px] items-center">
          <Button variant="pill" onClick={() => AdminActions.spectatePlayer(player.id)}>
            Spectate
          </Button>
          <Select value={slapAmount} onChange={(e) => setSlapAmount(Number(e.target.value))}>
            <option value="20">Slap: 20</option>
            <option value="50">Slap: 50</option>
            <option value="100">Slap: 100</option>
          </Select>
          <Button variant="pill" onClick={() => AdminActions.slapPlayer(player.id, slapAmount)}>
            Slap
          </Button>
        </div>
      </div>

      <SectionLabel>Edit player</SectionLabel>
      <div className="flex items-center justify-between gap-4 py-3 border-b border-white/5">
        <div className="text-[#d7dae1] text-[13.5px] flex-shrink-0">Set</div>
        <div className="flex gap-[6px] flex-wrap justify-end bg-[#333a47] p-1 rounded-[9px] max-w-[420px]">
          {SET_LABELS.map((label) => (
            <Button key={label} variant="pill" onClick={() => handleSetButton(label)}>
              {label}
            </Button>
          ))}
        </div>
      </div>

      <SectionLabel>Items</SectionLabel>
      <div className="flex items-center justify-between py-3 border-b border-white/5">
        <div className="text-[#d7dae1] text-[13.5px]">Weapon</div>
        <div className="flex gap-[6px]">
          <input
            type="number"
            min={1}
            max={46}
            value={weaponId}
            onChange={(e) => {
              const n = Number(e.target.value);
              if (Number.isFinite(n)) setWeaponId(Math.min(46, Math.max(1, Math.round(n))));
            }}
            placeholder="ID"
            title="Weapon ID (1-46)"
            className="w-[52px] bg-[#333a47] border-none rounded-[7px] px-2 py-[7px] text-[#e7e9ee] text-[12px] font-mono outline-none"
          />
          <Select value={weaponId} onChange={(e) => setWeaponId(Number(e.target.value))}>
            {Object.entries(WEAPON_IDS).map(([name, id]) => (
              <option key={id} value={id}>
                {name}
              </option>
            ))}
          </Select>
          <Button variant="pill" onClick={() => AdminActions.givePlayerWeapon(player.id, weaponId)}>
            Give
          </Button>
        </div>
      </div>
      <div className="flex items-center justify-between py-3 border-b border-white/5">
        <div className="text-[#d7dae1] text-[13.5px]">Vehicle</div>
        <div className="flex gap-[6px]">
          <input
            type="number"
            min={400}
            max={611}
            value={vehicleModelId}
            onChange={(e) => {
              const n = Number(e.target.value);
              if (Number.isFinite(n)) setVehicleModelId(Math.min(611, Math.max(400, Math.round(n))));
            }}
            placeholder="ID"
            title="Vehicle model ID (400-611)"
            className="w-[52px] bg-[#333a47] border-none rounded-[7px] px-2 py-[7px] text-[#e7e9ee] text-[12px] font-mono outline-none"
          />
          <Select value={vehicleModelId} onChange={(e) => setVehicleModelId(Number(e.target.value))}>
            {Object.entries(VEHICLE_MODEL_IDS).map(([name, id]) => (
              <option key={id} value={id}>
                {name}
              </option>
            ))}
          </Select>
          <Button variant="pill" onClick={() => AdminActions.givePlayerVehicle(player.id, vehicleModelId)}>
            Give
          </Button>
        </div>
      </div>
      <div className="flex items-center justify-between gap-4 py-3 border-b border-white/5">
        <div className="text-[#d7dae1] text-[13.5px] flex-shrink-0">Extra</div>
        <div className="flex gap-[6px] flex-wrap justify-end">
          <Button variant="pill" onClick={() => AdminActions.givePlayerJetpack(player.id)}>
            {player.jetpack ? 'Remove JetPack' : 'Give JetPack'}
          </Button>
          <Button variant="pill" onClick={() => AdminActions.warpToPlayer(player.id)}>
            Warp to player
          </Button>
          <Button variant="pill" onClick={() => AdminActions.warpPlayerToMe(player.id)}>
            Warp player to…
          </Button>
        </div>
      </div>

      <SectionLabel>Current vehicle</SectionLabel>
      <div className="flex items-center justify-between gap-4 py-3 border-b border-white/5">
        <div className="text-[#d7dae1] text-[13.5px] flex-shrink-0">Maintenance</div>
        <div className="flex gap-[6px] flex-wrap justify-end bg-[#333a47] p-1 rounded-[9px]">
          {VEHICLE_LABELS.map((label) => (
            <Button
              key={label}
              variant={DANGER_VEHICLE_LABELS.includes(label) ? 'pillDanger' : 'pill'}
              onClick={() =>
                label === 'Customize'
                  ? onOpenVehicleCustomize()
                  : AdminActions.vehicleMaintenance(player.id, VEHICLE_ACTION_BY_LABEL[label])
              }
            >
              {label}
            </Button>
          ))}
        </div>
      </div>
      <div className="flex items-center justify-between gap-4 py-3 border-b border-white/5">
        <div className="text-[#d7dae1] text-[13.5px] flex-shrink-0">Advanced</div>
        <div className="flex gap-[6px]">
          <Button
            variant="pill"
            onClick={() =>
              onRequestInput({
                title: 'Set Dimension',
                label: 'New dimension:',
                onConfirm: (value) => value.trim() && AdminActions.setVehicleDimension(player.id, value.trim()),
              })
            }
          >
            Set Dimens.
          </Button>
          <Select
            defaultValue=""
            onChange={(e) => {
              const loc = INTERIOR_LOCATIONS.find((l) => l.name === e.target.value);
              if (loc) AdminActions.teleportPlayerToInterior(player.id, loc.x, loc.y, loc.z, loc.interior);
              e.target.value = '';
            }}
          >
            <option value="" disabled>
              Teleport to interior…
            </option>
            {INTERIOR_LOCATIONS.map((loc) => (
              <option key={loc.name} value={loc.name}>
                {loc.name}
              </option>
            ))}
          </Select>
        </div>
      </div>

      <SectionLabel>Preferences</SectionLabel>
      {TOGGLE_DEFS.map((t) => (
        <div key={t.key} className="flex items-center justify-between py-3 border-b border-white/5">
          <div className="text-[#d7dae1] text-[13.5px]">{t.label}</div>
          <Toggle on={toggles[t.key]} onToggle={() => onToggleChange(t.key)} />
        </div>
      ))}
    </div>
  );
};
