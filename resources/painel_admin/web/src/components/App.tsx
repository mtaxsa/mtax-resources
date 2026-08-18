import React, { useMemo, useState } from 'react';
import { MANUAL_ZOOM_OPTIONS, ZOOM_OVERRIDE_STORAGE_KEY } from '../config/zoomConfig';
import { useNuiEvent } from '../hooks/useNuiEvent';
import { useNuiKeyboard } from '../hooks/useNuiKeyboard';
import { useViewportScale } from '../hooks/useViewportScale';
import { AclModal } from './AdminPanel/AclModal';
import { AdminActions } from './AdminPanel/actions';
import { BansTab } from './AdminPanel/BansTab';
import { ACL_GROUPS, BANS, PLAYERS, RESOURCES, SERVER_SETTINGS } from './AdminPanel/data';
import { PlayersTab, PromptRequest } from './AdminPanel/PlayersTab';
import { PromptModal } from './AdminPanel/PromptModal';
import { ResourcesTab } from './AdminPanel/ResourcesTab';
import { ServerTab } from './AdminPanel/ServerTab';
import { Sidebar } from './AdminPanel/Sidebar';
import type { AclGroup, Ban, Player, Resource, ResourceState, ServerSettings, TabName, TogglesState } from './AdminPanel/types';
import { Select } from './AdminPanel/ui';
import { VehicleCustomizeModal } from './AdminPanel/VehicleCustomizeModal';

// Panel is designed at a fixed 940x660 canvas; scale it as a whole so it
// keeps its proportions on any screen resolution instead of overflowing or
// being cropped (same approach as the Arsenal panel).
const PANEL_WIDTH = 940;
const PANEL_HEIGHT = 660;

const App: React.FC = () => {
  const [show, setShow] = useState(false);

  const [activeTab, setActiveTab] = useState<TabName>('Players');

  // Seeded with local mock data so the panel still renders something useful
  // in a plain browser; client.lua overwrites these via `setPlayers` /
  // `setResources` / `setBans` / `setAclGroups` NUI messages once connected.
  const [players, setPlayers] = useState<Player[]>(PLAYERS);
  const [resources, setResources] = useState<Resource[]>(RESOURCES);
  const [bans, setBans] = useState<Ban[]>(BANS);
  const [aclGroups, setAclGroups] = useState<AclGroup[]>(ACL_GROUPS);
  const [serverSettings, setServerSettings] = useState<ServerSettings>(SERVER_SETTINGS);

  const [search, setSearch] = useState('');
  const [selectedId, setSelectedId] = useState(0);

  const [resourceSearch, setResourceSearch] = useState('');
  const [selectedResourceId, setSelectedResourceId] = useState(0);
  const [resourceOverrides, setResourceOverrides] = useState<Record<number, ResourceState>>({});

  const [bansSearch, setBansSearch] = useState('');
  const [selectedBanId, setSelectedBanId] = useState<number | null>(null);

  const [actionLog, setActionLog] = useState<string[]>([]);
  const [toggles, setToggles] = useState<TogglesState>({ hideSensitive: false });

  const [aclModalOpen, setAclModalOpen] = useState(false);
  const [expandedAclGroup, setExpandedAclGroup] = useState<string | null>(null);

  const [vehicleCustomizeOpen, setVehicleCustomizeOpen] = useState(false);

  const [prompt, setPrompt] = useState<PromptRequest | null>(null);
  const requestInput = (request: PromptRequest) => setPrompt(request);

  // Manual zoom override, persisted per-browser (localStorage survives panel
  // reopens/resource restarts) so each admin can override the automatic
  // per-resolution zoom (config/zoomConfig.ts) if it doesn't suit their screen.
  const [zoomOverride, setZoomOverride] = useState<number | null>(() => {
    const stored = Number(localStorage.getItem(ZOOM_OVERRIDE_STORAGE_KEY));
    return Number.isFinite(stored) && stored > 0 ? stored : null;
  });
  const handleZoomChange = (value: string) => {
    if (value === 'auto') {
      setZoomOverride(null);
      localStorage.removeItem(ZOOM_OVERRIDE_STORAGE_KEY);
      return;
    }
    const percent = Number(value);
    setZoomOverride(percent);
    localStorage.setItem(ZOOM_OVERRIDE_STORAGE_KEY, String(percent));
  };

  const scale = useViewportScale(PANEL_WIDTH, PANEL_HEIGHT, 32, zoomOverride);

  useNuiEvent<boolean>('toggle', (visible) => {
    setShow(visible);
    if (visible) {
      // Panel just opened — ask client.lua for a fresh snapshot of everything.
      AdminActions.getPlayers().then((res) => Array.isArray(res) && setPlayers(res)).catch(() => {});
      AdminActions.getResources().then((res) => Array.isArray(res) && setResources(res)).catch(() => {});
      AdminActions.getBans().then((res) => Array.isArray(res) && setBans(res)).catch(() => {});
      AdminActions.getAclGroups().then((res) => Array.isArray(res) && setAclGroups(res)).catch(() => {});
      AdminActions.getServerSettings().then((res) => res && setServerSettings(res)).catch(() => {});
      AdminActions.getActionLog().then((res) => Array.isArray(res) && setActionLog(res)).catch(() => {});
    }
  });

  useNuiEvent<Player[]>('setPlayers', setPlayers);
  useNuiEvent<Resource[]>('setResources', setResources);
  useNuiEvent<Ban[]>('setBans', setBans);
  useNuiEvent<AclGroup[]>('setAclGroups', setAclGroups);
  useNuiEvent<ServerSettings>('setServerSettings', setServerSettings);
  useNuiEvent<string[]>('setActionLog', setActionLog);

  const handleClose = () => {
    setShow(false);
    AdminActions.closePanel();
  };

  useNuiKeyboard('Escape', () => {
    if (prompt) return setPrompt(null);
    if (aclModalOpen) return setAclModalOpen(false);
    if (vehicleCustomizeOpen) return setVehicleCustomizeOpen(false);
    handleClose();
  });

  const playerOptions = useMemo(() => {
    const filtered = players.filter((p) => p.name.toLowerCase().includes(search.toLowerCase()));
    return filtered.length ? filtered : players;
  }, [players, search]);
  const player = players.find((p) => p.id === selectedId) ?? players[0];

  const filteredResources = useMemo(
    () => resources.filter((r) => r.name.toLowerCase().includes(resourceSearch.toLowerCase())),
    [resources, resourceSearch]
  );
  const selectedResource = resources.find((r) => r.id === selectedResourceId) ?? resources[0];

  const filteredBans = useMemo(() => {
    const q = bansSearch.toLowerCase();
    return bans.filter((b) => b.name.toLowerCase().includes(q) || b.ip.includes(bansSearch) || b.serial.toLowerCase().includes(q));
  }, [bans, bansSearch]);

  const handleToggleChange = (key: keyof TogglesState) => {
    setToggles((prev) => ({ ...prev, [key]: !prev[key] }));
  };

  const handleSetResourceState = (id: number, state: ResourceState) => {
    setResourceOverrides((prev) => ({ ...prev, [id]: state }));
  };

  const handleToggleAclGroup = (name: string) => {
    setExpandedAclGroup((prev) => (prev === name ? null : name));
  };

  return (
    show ?
    <div
      className={`w-full h-full flex items-center justify-center font-sora transition-opacity duration-150 ${
        show ? 'opacity-100' : 'opacity-0 pointer-events-none'
      }`}
    >
      <div className="shrink-0" style={{ transform: `scale(${scale})` }}>
        <div className="w-[940px] h-[660px] rounded-[18px] bg-[#262c37] border border-white/[0.06] shadow-[0_40px_90px_-20px_rgba(0,0,0,0.75)] flex overflow-hidden">
          <Sidebar activeTab={activeTab} onTabChange={setActiveTab} search={search} onSearchChange={setSearch} />

          <div className="flex-1 flex flex-col min-w-0">
            <div className="flex items-center justify-between px-[28px] pt-[22px] pb-1">
              <div className="text-[#f0f2f6] text-[18px] font-bold">{activeTab}</div>
              <div className="flex items-center gap-[10px]">
                <Select value={zoomOverride ?? 'auto'} onChange={(e) => handleZoomChange(e.target.value)} title="Zoom">
                  <option value="auto">Zoom: Auto</option>
                  {MANUAL_ZOOM_OPTIONS.map((p) => (
                    <option key={p} value={p}>
                      Zoom: {Math.round(p * 100)}%
                    </option>
                  ))}
                </Select>
                <div
                  onClick={handleClose}
                  className="w-[26px] h-[26px] rounded-[7px] flex items-center justify-center text-[#6b7280] text-[15px] cursor-pointer"
                >
                  ✕
                </div>
              </div>
            </div>

            {activeTab === 'Players' && player && (
              <PlayersTab
                playerOptions={playerOptions}
                player={player}
                onSelectPlayer={setSelectedId}
                toggles={toggles}
                onToggleChange={handleToggleChange}
                onRequestInput={requestInput}
                onOpenVehicleCustomize={() => setVehicleCustomizeOpen(true)}
              />
            )}

            {activeTab === 'Resources' && selectedResource && (
              <ResourcesTab
                resourceSearch={resourceSearch}
                onResourceSearchChange={setResourceSearch}
                resources={filteredResources}
                selectedResource={selectedResource}
                selectedResourceId={selectedResource.id}
                onSelectResource={setSelectedResourceId}
                resourceOverrides={resourceOverrides}
                onSetResourceState={handleSetResourceState}
                actionLog={actionLog}
                onOpenAclModal={() => setAclModalOpen(true)}
              />
            )}

            {activeTab === 'Server' && (
              <ServerTab
                serverName={serverSettings.serverName}
                serverPassword={serverSettings.password}
                weatherId={serverSettings.weatherId}
                onlinePlayers={serverSettings.onlinePlayers}
                maxPlayers={serverSettings.maxPlayers}
                onWeatherIdChange={(weatherId) => setServerSettings((prev) => ({ ...prev, weatherId }))}
                onRequestInput={requestInput}
              />
            )}

            {activeTab === 'Bans' && (
              <BansTab
                bansSearch={bansSearch}
                onBansSearchChange={setBansSearch}
                bans={filteredBans}
                totalBans={bans.length}
                selectedBanId={selectedBanId}
                onSelectBan={setSelectedBanId}
              />
            )}
          </div>
        </div>
      </div>

      {aclModalOpen && (
        <AclModal
          onClose={() => setAclModalOpen(false)}
          groups={aclGroups}
          expandedGroup={expandedAclGroup}
          onToggleGroup={handleToggleAclGroup}
          onRequestInput={requestInput}
          scale={scale}
        />
      )}

      {vehicleCustomizeOpen && player && (
        <VehicleCustomizeModal player={player} onClose={() => setVehicleCustomizeOpen(false)} scale={scale} />
      )}

      <PromptModal
        open={!!prompt}
        title={prompt?.title ?? ''}
        label={prompt?.label ?? ''}
        confirmLabel={prompt?.confirmLabel}
        defaultValue={prompt?.defaultValue}
        onConfirm={(value) => {
          prompt?.onConfirm(value);
          setPrompt(null);
        }}
        onCancel={() => setPrompt(null)}
        scale={scale}
      />
    </div>
    : <></>
  );
};

export default App;
