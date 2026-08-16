import React, { useEffect, useRef, useState } from 'react';
import { useWheelScroll } from '../../hooks/useWheelScroll';
import { AdminActions } from './actions';
import type { AclGroup } from './types';
import { Button } from './ui';

interface AclModalProps {
  onClose: () => void;
  groups: AclGroup[];
  expandedGroup: string | null;
  onToggleGroup: (name: string) => void;
  onRequestInput: (opts: { title: string; label: string; confirmLabel?: string; onConfirm: (value: string) => void }) => void;
  scale: number;
}

const stopClick = (e: React.MouseEvent) => e.stopPropagation();

export const AclModal: React.FC<AclModalProps> = ({ onClose, groups, expandedGroup, onToggleGroup, onRequestInput, scale }) => {
  const scrollRef = useRef<HTMLDivElement>(null);
  const removeListRef = useRef<HTMLDivElement>(null);
  const [removingObject, setRemovingObject] = useState(false);

  // CEF OSR drops wheel events after the native scrollbar thumb is dragged
  // (cef/cef#3567); route the wheel through JS so it never depends on that path.
  useWheelScroll(scrollRef);
  useWheelScroll(removeListRef);

  useEffect(() => {
    setRemovingObject(false);
  }, [expandedGroup]);

  const expandedGroupData = groups.find((g) => g.name === expandedGroup) ?? null;

  const requestNamed = (title: string, label: string, action: Parameters<typeof AdminActions.aclGroupAction>[0]) =>
    onRequestInput({
      title,
      label,
      onConfirm: (value) => {
        if (value.trim()) AdminActions.aclGroupAction(action, expandedGroup, value.trim());
      },
    });

  const handleRemoveObject = (object: string) => {
    if (!expandedGroup) return;
    AdminActions.aclGroupAction('removeObject', expandedGroup, object);
    setRemovingObject(false);
  };

  return (
    <div onClick={onClose} className="fixed inset-0 bg-black/55 flex items-center justify-center z-50">
      <div onClick={stopClick} className="shrink-0" style={{ transform: `scale(${scale})` }}>
        <div className="w-[620px] max-w-[92vw] h-[500px] rounded-2xl bg-[#262c37] border border-white/[0.07] shadow-[0_40px_90px_-20px_rgba(0,0,0,0.75)] flex flex-col overflow-hidden relative">
          <div className="text-center py-[14px] pb-[14px] border-b border-white/[0.06] text-[#f0f2f6] text-[15px] font-bold">
            ACL Management
          </div>

          <div className="flex-1 flex min-h-0">
            <div ref={scrollRef} className="op-scroll flex-1 overflow-y-auto pt-[14px] pr-[10px] pb-[14px] pl-[18px] border-r border-white/[0.06]">
              <div className="text-[#6b7280] text-[11px] font-bold tracking-[0.8px] uppercase mb-2">Groups</div>
              {groups.map((group) => {
                const expanded = group.name === expandedGroup;
                return (
                  <div key={group.name}>
                    <div
                      onClick={() => onToggleGroup(group.name)}
                      className={`flex items-center px-2 py-[5px] rounded-[6px] cursor-pointer text-[12.5px] ${
                        expanded ? 'text-[#f0f2f6] font-semibold bg-[rgba(91,141,239,0.14)]' : 'text-[#c7cbd3] font-medium bg-transparent'
                      }`}
                    >
                      <span className="inline-block w-4 text-[#767d89] font-mono">{expanded ? '−' : '+'}</span>
                      {group.name}
                    </div>
                    {expanded && (
                      <div className="pl-[22px] text-[#767d89] text-[12px] font-mono leading-[1.7]">
                        <div>objects:</div>
                        {group.objects.length > 0 ? (
                          group.objects.map((object) => (
                            <div key={object} className="pl-4">
                              {object}
                            </div>
                          ))
                        ) : (
                          <div className="pl-4 text-[#565c66]">(none)</div>
                        )}
                      </div>
                    )}
                  </div>
                );
              })}
            </div>

            <div className="w-[220px] flex-shrink-0 p-4 flex flex-col gap-1">
              <Button
                variant="modalRow"
                onClick={() => requestNamed('Create Group', 'Group name:', 'createGroup')}
              >
                Create group
              </Button>
              <div className="h-px bg-white/[0.06] my-2" />
              <div className="text-[#d7dae1] text-[12.5px] font-semibold px-[10px] pt-[6px] pb-[10px]">
                Group: {expandedGroup || '—'}
              </div>
              <Button
                variant="modalRowDanger"
                disabled={!expandedGroup}
                className="disabled:opacity-40 disabled:pointer-events-none"
                onClick={() => expandedGroup && AdminActions.aclGroupAction('destroyGroup', expandedGroup)}
              >
                Destroy group
              </Button>
              <Button
                variant="modalRow"
                disabled={!expandedGroup}
                className="disabled:opacity-40 disabled:pointer-events-none"
                onClick={() => requestNamed('Add Object', 'Enter object name:', 'addObject')}
              >
                Add Object
              </Button>
              <Button
                variant="modalRow"
                disabled={!expandedGroup}
                className="disabled:opacity-40 disabled:pointer-events-none"
                onClick={() => setRemovingObject((prev) => !prev)}
              >
                Remove Object
              </Button>

              {removingObject && expandedGroupData && (
                <div
                  ref={removeListRef}
                  className="op-scroll max-h-[140px] overflow-y-auto rounded-[7px] bg-[#20252f] border border-white/[0.06] py-1"
                >
                  {expandedGroupData.objects.length > 0 ? (
                    expandedGroupData.objects.map((object) => (
                      <button
                        key={object}
                        type="button"
                        onClick={() => handleRemoveObject(object)}
                        className="w-full text-left px-[10px] py-[6px] text-[12px] font-mono text-[#f2637d] hover:bg-white/5 truncate"
                      >
                        {object}
                      </button>
                    ))
                  ) : (
                    <div className="px-[10px] py-[8px] text-[12px] text-[#565c66]">No objects in this group.</div>
                  )}
                </div>
              )}
            </div>
          </div>

          <div className="flex justify-end px-4 py-3 border-t border-white/[0.06]">
            <Button variant="pill" onClick={onClose}>
              Close
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
};
