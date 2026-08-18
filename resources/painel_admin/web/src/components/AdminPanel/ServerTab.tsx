import React, { useRef, useState } from 'react';
import { useWheelScroll } from '../../hooks/useWheelScroll';
import { AdminActions } from './actions';
import { getWeatherLabel } from './data';
import type { PromptRequest } from './PlayersTab';
import { Button, SectionLabel } from './ui';

interface ServerTabProps {
  serverName: string;
  serverPassword: string;
  weatherId: number;
  onlinePlayers: number;
  maxPlayers: number;
  onWeatherIdChange: (weatherId: number) => void;
  onRequestInput: (request: PromptRequest) => void;
}

const WEATHER_MIN = 0;
const WEATHER_MAX = 44;

const SERVER_ENV_FIELD_DEFS = [
  { key: 'time', label: 'Time', defaultValue: '13:00', hint: '(0-23:0-59)', action: AdminActions.setTime },
  { key: 'gravity', label: 'Gravitation', defaultValue: '0.0080', hint: '(0-10)', action: AdminActions.setGravity },
  { key: 'gameSpeed', label: 'Game Speed', defaultValue: '1', hint: '', action: AdminActions.setGameSpeed },
  { key: 'waveHeight', label: 'Wave Height', defaultValue: '0', hint: '(0-100)', action: AdminActions.setWaveHeight },
  { key: 'fpsLimit', label: 'FPS Limit', defaultValue: '60', hint: '(25-150)', action: AdminActions.setFpsLimit },
] as const;

export const ServerTab: React.FC<ServerTabProps> = ({
  serverName,
  serverPassword,
  weatherId,
  onlinePlayers,
  maxPlayers,
  onWeatherIdChange,
  onRequestInput,
}) => {
  const [envValues, setEnvValues] = useState<Record<string, string>>(
    Object.fromEntries(SERVER_ENV_FIELD_DEFS.map((f) => [f.key, f.defaultValue]))
  );
  const scrollRef = useRef<HTMLDivElement>(null);

  // CEF OSR drops wheel events after the native scrollbar thumb is dragged
  // (cef/cef#3567); route the wheel through JS so it never depends on that path.
  useWheelScroll(scrollRef);

  return (
    <div ref={scrollRef} className="op-scroll flex-1 overflow-y-auto px-[28px] pt-2 pb-[28px]">
      <SectionLabel first>Server</SectionLabel>

      <div className="flex items-center justify-between gap-4 py-3 border-b border-white/5">
        <div className="text-[#d7dae1] text-[13.5px] flex-shrink-0">Server name</div>
        <div className="text-[#9aa1ad] text-[12.5px] font-mono bg-[#333a47] px-3 py-[6px] rounded-[7px]">
          {serverName || '—'}
        </div>
      </div>

      <div className="flex items-center justify-between gap-4 py-3 border-b border-white/5">
        <div className="text-[#d7dae1] text-[13.5px] flex-shrink-0">Password</div>
        <div className="flex items-center gap-2">
          <div className="text-[#9aa1ad] text-[12.5px] font-mono bg-[#333a47] px-3 py-[6px] rounded-[7px]">
            {serverPassword || 'None'}
          </div>
          <Button
            variant="pill"
            onClick={() =>
              onRequestInput({
                title: 'Server password',
                label: 'New password (leave empty to remove):',
                onConfirm: (value) => AdminActions.setServerPassword(value.trim()),
              })
            }
          >
            Set / Reset Password
          </Button>
        </div>
      </div>

      <div className="flex items-center justify-between gap-4 py-3 border-b border-white/5">
        <div className="text-[#d7dae1] text-[13.5px] flex-shrink-0">Players</div>
        <div className="text-[#9aa1ad] text-[12.5px] font-mono bg-[#333a47] px-3 py-[6px] rounded-[7px]">
          {onlinePlayers}/{maxPlayers}
        </div>
      </div>

      <SectionLabel>Environment</SectionLabel>
      <div className="flex items-center justify-between gap-4 py-3 border-b border-white/5">
        <div className="text-[#d7dae1] text-[13.5px] flex-shrink-0">Weather</div>
        <div className="flex items-center gap-2">
          <Button variant="step" onClick={() => onWeatherIdChange(Math.max(WEATHER_MIN, weatherId - 1))}>
            ‹
          </Button>
          <div className="text-[#d7dae1] text-[12.5px] font-mono bg-[#333a47] px-[14px] py-[6px] rounded-[7px] min-w-[150px] text-center">
            {weatherId} ({getWeatherLabel(weatherId)})
          </div>
          <Button variant="step" onClick={() => onWeatherIdChange(Math.min(WEATHER_MAX, weatherId + 1))}>
            ›
          </Button>
          <Button variant="pill" onClick={() => AdminActions.setWeather(weatherId, false)}>
            Set
          </Button>
          <Button
            variant="pill"
            onClick={() => {
              const randomId = Math.floor(Math.random() * (WEATHER_MAX - WEATHER_MIN + 1)) + WEATHER_MIN;
              onWeatherIdChange(randomId);
              AdminActions.setWeather(randomId, true);
            }}
          >
            Set Blended
          </Button>
        </div>
      </div>

      {SERVER_ENV_FIELD_DEFS.map((f) => (
        <div key={f.key} className="flex items-center justify-between gap-4 py-3 border-b border-white/5">
          <div className="text-[#d7dae1] text-[13.5px] flex-shrink-0">{f.label}</div>
          <div className="flex items-center gap-2">
            <input
              value={envValues[f.key]}
              onChange={(e) => setEnvValues((prev) => ({ ...prev, [f.key]: e.target.value }))}
              className="w-[90px] bg-[#333a47] border-none rounded-[7px] px-[10px] py-[7px] text-[#e7e9ee] text-[12.5px] font-mono outline-none"
            />
            <Button variant="pill" onClick={() => f.action(envValues[f.key])}>
              Set
            </Button>
            <div className="text-[#55606e] text-[11.5px] font-mono w-[90px]">{f.hint}</div>
          </div>
        </div>
      ))}

      <SectionLabel>Actions</SectionLabel>
      <div className="flex items-center justify-between gap-4 py-3">
        <div className="text-[#d7dae1] text-[13.5px] flex-shrink-0">Server</div>
        <div className="flex gap-[6px]">
          {/* <Button
            variant="pill"
            onClick={() =>
              onRequestInput({
                title: 'Welcome Message',
                label: 'Welcome message:',
                onConfirm: (value) => value.trim() && AdminActions.sendWelcomeMessage(value.trim()),
              })
            }
          >
            Welcome Message
          </Button> */}
          <Button variant="pillDanger" onClick={() => AdminActions.shutdownServer()}>
            Shutdown
          </Button>
          {/* <Button variant="pill" onClick={() => AdminActions.clearChat()}>
            Clear Chat
          </Button> */}
        </div>
      </div>
    </div>
  );
};
