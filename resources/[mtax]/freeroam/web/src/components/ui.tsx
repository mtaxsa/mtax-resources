import type { LucideIcon } from 'lucide-react';
import React from 'react';

type Variant = 'default' | 'primary' | 'danger' | 'ghost';

const VARIANTS: Record<Variant, string> = {
  default: 'bg-raised text-ink hover:bg-white/12',
  primary: 'bg-accent text-white shadow-[0_6px_18px_rgb(255_77_141/0.28)] hover:brightness-110',
  danger: 'bg-bad/12 text-[#ff8f8f] hover:bg-bad/22',
  ghost: 'text-ink-dim hover:bg-raised hover:text-ink',
};

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: Variant;
  active?: boolean;
  icon?: LucideIcon;
}

export const Button: React.FC<ButtonProps> = ({ variant = 'default', active, icon: Icon, className = '', children, ...rest }) => (
  <button
    {...rest}
    className={`flex h-9 items-center justify-center gap-2 truncate rounded-lg px-4 text-[13px] font-semibold outline-none transition ${
      active ? 'bg-brand/15 text-ink ring-1 ring-brand/50' : VARIANTS[variant]
    } ${className}`}
  >
    {Icon && <Icon size={15} strokeWidth={2.2} className="shrink-0" />}
    {children}
  </button>
);

export const Switch: React.FC<{ on: boolean }> = ({ on }) => (
  <span
    className={`relative h-[20px] w-[36px] shrink-0 rounded-full transition-colors ${on ? 'bg-accent' : 'bg-white/12'}`}
  >
    <span
      className="absolute top-[3px] h-[14px] w-[14px] rounded-full bg-white shadow transition-all"
      style={{ left: on ? 19 : 3 }}
    />
  </span>
);

interface ToggleRowProps {
  icon: LucideIcon;
  label: string;
  on: boolean;
  disabled?: boolean;
  onChange: (next: boolean) => void;
}

export const ToggleRow: React.FC<ToggleRowProps> = ({ icon: Icon, label, on, disabled, onChange }) => (
  <button
    disabled={disabled}
    onClick={() => onChange(!on)}
    className="flex w-full items-center gap-3 px-3.5 py-2.5 text-left outline-none transition-colors hover:bg-raised"
  >
    <Icon size={16} strokeWidth={2} className={on ? 'text-brand' : 'text-ink-faint'} />
    <span className="min-w-0 flex-1 truncate text-[13px] text-ink">{label}</span>
    <Switch on={on} />
  </button>
);

export const Card: React.FC<{ children: React.ReactNode; className?: string }> = ({ children, className = '' }) => (
  <div className={`overflow-hidden rounded-xl border border-line bg-surface ${className}`}>{children}</div>
);

export const SectionLabel: React.FC<{ children: React.ReactNode; className?: string }> = ({ children, className = '' }) => (
  <div className={`mb-2 text-[11px] font-semibold tracking-wider text-ink-faint uppercase ${className}`}>{children}</div>
);

interface TileProps {
  icon: LucideIcon;
  label: string;
  active?: boolean;
  danger?: boolean;
  disabled?: boolean;
  onClick: () => void;
}

export const Tile: React.FC<TileProps> = ({ icon: Icon, label, active, danger, disabled, onClick }) => (
  <button
    disabled={disabled}
    onClick={onClick}
    className={`group flex h-[70px] flex-col items-center justify-center gap-1.5 rounded-xl border px-1 outline-none transition ${
      active
        ? 'border-brand/60 bg-brand/12'
        : danger
          ? 'border-bad/25 bg-bad/8 hover:border-bad/50 hover:bg-bad/15'
          : 'border-line bg-surface hover:border-white/15 hover:bg-raised'
    }`}
  >
    <Icon
      size={20}
      strokeWidth={1.9}
      className={active ? 'text-brand' : danger ? 'text-[#ff8f8f]' : 'text-ink-dim transition-colors group-hover:text-ink'}
    />
    <span className={`max-w-full truncate text-[12px] font-medium ${danger ? 'text-[#ff8f8f]' : 'text-ink'}`}>{label}</span>
  </button>
);

type InputProps = React.InputHTMLAttributes<HTMLInputElement> & { icon?: LucideIcon };

export const Input = React.forwardRef<HTMLInputElement, InputProps>(({ className = '', icon: Icon, ...rest }, ref) => (
  <div className={`relative ${className}`}>
    {Icon && (
      <Icon size={15} className="pointer-events-none absolute top-1/2 left-3 -translate-y-1/2 text-ink-faint" />
    )}
    <input
      ref={ref}
      type="text"
      {...rest}
      className={`h-9 w-full rounded-lg border border-line bg-black/30 text-[13px] text-ink outline-none transition-colors placeholder:text-ink-faint focus:border-brand/60 ${
        Icon ? 'pr-3 pl-9' : 'px-3'
      }`}
    />
  </div>
));
