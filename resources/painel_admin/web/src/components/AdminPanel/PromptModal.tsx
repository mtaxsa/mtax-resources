import React, { useEffect, useState } from 'react';
import { Button } from './ui';

interface PromptModalProps {
  open: boolean;
  title: string;
  label: string;
  confirmLabel?: string;
  defaultValue?: string;
  onConfirm: (value: string) => void;
  onCancel: () => void;
  scale: number;
}

const stopClick = (e: React.MouseEvent) => e.stopPropagation();

export const PromptModal: React.FC<PromptModalProps> = ({
  open,
  title,
  label,
  confirmLabel = 'Ok',
  defaultValue = '',
  onConfirm,
  onCancel,
  scale,
}) => {
  const [value, setValue] = useState(defaultValue);

  useEffect(() => {
    if (open) setValue(defaultValue);
  }, [open, defaultValue]);

  if (!open) return null;

  return (
    <div onClick={onCancel} className="fixed inset-0 bg-black/50 flex items-center justify-center z-[60]">
      <div onClick={stopClick} className="shrink-0" style={{ transform: `scale(${scale})` }}>
        <div className="w-[300px] rounded-[14px] bg-[#22252c] border border-white/[0.08] shadow-[0_30px_60px_-15px_rgba(0,0,0,0.6)] overflow-hidden">
          <div className="text-center py-[14px] pb-3 border-b border-white/[0.06] text-[#f0f2f6] text-[14px] font-bold">{title}</div>
          <div className="px-[18px] pt-[18px] pb-4">
            <div className="text-[#9aa1ad] text-[12.5px] mb-2">{label}</div>
            <input
              value={value}
              onChange={(e) => setValue(e.target.value)}
              autoFocus
              className="w-full bg-[#20252f] border-none rounded-[8px] px-3 py-[9px] text-[#e7e9ee] text-[13px] font-mono outline-none"
            />
            <div className="flex gap-2 justify-center mt-4">
              <Button variant="primary" onClick={() => onConfirm(value)}>
                {confirmLabel}
              </Button>
              <Button variant="outline" onClick={onCancel}>
                Cancel
              </Button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
