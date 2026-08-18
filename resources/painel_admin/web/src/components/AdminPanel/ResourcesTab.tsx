import React, { useEffect, useRef, useState } from 'react';
import { useWheelScroll } from '../../hooks/useWheelScroll';
import { AdminActions, ResourceLifecycleAction } from './actions';
import type { Resource, ResourceState } from './types';
import { Button, FieldRow, SearchInput, SectionLabel } from './ui';

interface ResourcesTabProps {
  resourceSearch: string;
  onResourceSearchChange: (value: string) => void;
  resources: Resource[];
  selectedResource: Resource;
  selectedResourceId: number;
  onSelectResource: (id: number) => void;
  resourceOverrides: Record<number, ResourceState>;
  onSetResourceState: (id: number, state: ResourceState) => void;
  actionLog: string[];
  onOpenAclModal: () => void;
}

export const ResourcesTab: React.FC<ResourcesTabProps> = ({
  resourceSearch,
  onResourceSearchChange,
  resources,
  selectedResource,
  selectedResourceId,
  onSelectResource,
  resourceOverrides,
  onSetResourceState,
  actionLog,
  onOpenAclModal,
}) => {
  const [command, setCommand] = useState('');
  const tabScrollRef = useRef<HTMLDivElement>(null);
  const listScrollRef = useRef<HTMLDivElement>(null);

  // CEF OSR drops wheel events after the native scrollbar thumb is dragged
  // (cef/cef#3567); route the wheel through JS so it never depends on that path.
  useWheelScroll(tabScrollRef);
  useWheelScroll(listScrollRef);

  useEffect(() => {
    if (listScrollRef.current) listScrollRef.current.scrollTop = 0;
  }, [resourceSearch]);

  // The Actions Log itself is server-authoritative (see server.lua's
  // ActionLog/PushActionLog + the 'setActionLog' broadcast) so every open
  // panel shows the same history — nothing to push locally here, a failed
  // round-trip just never produces a log entry for anyone.
  const runResourceAction = (resource: Resource, action: ResourceLifecycleAction, newState: ResourceState) => {
    onSetResourceState(resource.id, newState);
    AdminActions.resourceLifecycle(resource.name, action).catch(() => {});
  };

  const runCommand = (scope: 'client' | 'server') => {
    const trimmed = command.trim();
    if (!trimmed) return;
    // Clear as soon as the command is dispatched instead of waiting on the
    // NUI round-trip, so the field always resets right away even if the
    // response is slow (or never comes back).
    setCommand('');
    AdminActions.executeCommand(trimmed, scope).catch(() => {});
  };

  const handleRefresh = () => {
    AdminActions.refreshResources().catch(() => {});
  };

  return (
    <div ref={tabScrollRef} className="op-scroll flex-1 overflow-y-auto px-[28px] pt-2 pb-[28px]">
      <SectionLabel first>Resource</SectionLabel>

      <div className="mb-1">
        <SearchInput
          value={resourceSearch}
          onChange={(e) => onResourceSearchChange(e.target.value)}
          placeholder="Search resource"
        />
      </div>

      <div ref={listScrollRef} className="op-scroll h-[260px] overflow-y-auto border-b border-white/5 mb-1">
        {resources.map((r) => {
          const state = resourceOverrides[r.id] ?? r.state;
          const selected = r.id === selectedResourceId;
          return (
            <div
              key={r.id}
              onClick={() => onSelectResource(r.id)}
              className={`flex items-center py-[7px] px-2 rounded-[7px] cursor-pointer ${
                selected ? 'bg-[rgba(91,141,239,0.14)]' : 'bg-transparent'
              }`}
            >
              <div
                className={`text-[12.5px] whitespace-nowrap overflow-hidden text-ellipsis flex-1 min-w-0 ${
                  selected ? 'text-[#f0f2f6] font-semibold' : 'text-[#c7cbd3] font-medium'
                }`}
              >
                {r.name}
              </div>
              <div
                className={`text-[11px] font-mono flex-shrink-0 ml-[10px] w-[56px] text-right ${
                  state === 'running' ? 'text-[#5fd88a]' : 'text-[#8b93a1]'
                }`}
              >
                {state}
              </div>
              <div className="flex gap-[3px] flex-shrink-0 ml-2">
                <Button
                  variant="icon"
                  title="Start"
                  onClick={(e) => {
                    e.stopPropagation();
                    runResourceAction(r, 'start', 'running');
                  }}
                >
                  ▶
                </Button>
                <Button
                  variant="icon"
                  title="Restart"
                  onClick={(e) => {
                    e.stopPropagation();
                    runResourceAction(r, 'restart', 'running');
                  }}
                >
                  ↻
                </Button>
                <Button
                  variant="iconDanger"
                  title="Stop"
                  onClick={(e) => {
                    e.stopPropagation();
                    runResourceAction(r, 'stop', 'stopped');
                  }}
                >
                  ■
                </Button>
              </div>
            </div>
          );
        })}
      </div>

      <FieldRow label="Full Name" value={selectedResource.fullName} />
      <FieldRow label="Author" value={selectedResource.author} />
      <FieldRow label="Version" value={selectedResource.version} />

      <div className="flex items-center justify-between gap-4 py-3 border-b border-white/5">
        <div className="text-[#d7dae1] text-[13.5px] flex-shrink-0">Server permissions</div>
        <Button variant="pill" onClick={onOpenAclModal}>
          Manage ACL
        </Button>
      </div>

      <SectionLabel>Console</SectionLabel>
      <div className="py-3 border-b border-white/5">
        <div className="text-[#d7dae1] text-[13.5px] mb-2">Execute Command</div>
        <div className="flex gap-2">
          <input
            value={command}
            onChange={(e) => setCommand(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && runCommand('server')}
            placeholder="For advanced users only."
            className="flex-1 bg-[#333a47] border-none rounded-[8px] px-3 py-[9px] text-[#f2637d] text-[12.5px] font-mono outline-none placeholder:text-[#f2637d]/60"
          />
          <Button variant="pill" onClick={() => runCommand('client')}>
            Client
          </Button>
          <Button variant="pill" onClick={() => runCommand('server')}>
            Server
          </Button>
        </div>
      </div>

      <div className="py-3 border-b border-white/5">
        <div className="text-[#d7dae1] text-[13.5px] mb-2">Actions Log</div>
        <div className="bg-[#20252f] rounded-[8px] px-3 py-[10px] min-h-[64px] text-[#55606e] text-[12px] font-mono whitespace-pre-wrap">
          {actionLog.length === 0 ? 'No actions logged yet.' : actionLog.join('\n')}
        </div>
      </div>

      <div className="flex items-center justify-end py-3">
        <Button variant="pill" onClick={handleRefresh}>
          Refresh list
        </Button>
      </div>
    </div>
  );
};
