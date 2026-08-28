import React from 'react';

type ButtonVariant =
  | 'pill'
  | 'pillDanger'
  | 'step'
  | 'icon'
  | 'iconDanger'
  | 'modalRow'
  | 'modalRowDanger'
  | 'primary'
  | 'outline';

const VARIANT_CLASSES: Record<ButtonVariant, string> = {
  pill: 'bg-[#3a4150] text-[#c7cbd3] rounded-[7px] px-[11px] py-[6px] text-[12px]',
  pillDanger: 'bg-[#3a4150] text-[#f2637d] rounded-[7px] px-[11px] py-[6px] text-[12px]',
  step: 'bg-[#3a4150] text-[#c7cbd3] rounded-[7px] w-[26px] h-[26px] text-[14px] flex items-center justify-center flex-shrink-0',
  icon: 'bg-[#3a4150] text-[#c7cbd3] rounded-[6px] w-[22px] h-[22px] text-[10px] flex items-center justify-center leading-none flex-shrink-0',
  iconDanger: 'bg-[#3a4150] text-[#f2637d] rounded-[6px] w-[22px] h-[22px] text-[10px] flex items-center justify-center leading-none flex-shrink-0',
  modalRow: 'bg-transparent text-[#c7cbd3] rounded-[8px] px-[10px] py-[9px] text-[13px] text-left w-full',
  modalRowDanger: 'bg-transparent text-[#f2637d] rounded-[8px] px-[10px] py-[9px] text-[13px] text-left w-full',
  primary: 'bg-[#1f9d6f] text-white rounded-full px-5 py-2 text-[12.5px] font-semibold',
  outline: 'bg-transparent text-[#c7cbd3] rounded-full px-5 py-2 text-[12.5px] font-semibold border border-white/15',
};

const HOVER = 'hover:bg-[linear-gradient(135deg,_#f28fa4_0%,_#f6b98c_100%)] hover:text-white';

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: ButtonVariant;
}

export const Button: React.FC<ButtonProps> = ({ variant = 'pill', className = '', children, ...rest }) => (
  <button {...rest} className={`font-sora border-none cursor-pointer ${VARIANT_CLASSES[variant]} ${HOVER} ${className}`}>
    {children}
  </button>
);

export const SectionLabel: React.FC<{ children: React.ReactNode; first?: boolean }> = ({ children, first }) => (
  <div className={`text-[#6b7280] text-[11px] font-bold tracking-[0.8px] uppercase ${first ? 'mt-[18px]' : 'mt-[22px]'} mb-[6px]`}>
    {children}
  </div>
);

export const FieldRow: React.FC<{ label: string; value: string }> = ({ label, value }) => (
  <div className="flex items-center justify-between py-3 border-b border-white/5">
    <div className="text-[#d7dae1] text-[13.5px]">{label}</div>
    <div className="text-[#9aa1ad] text-[12.5px] font-mono bg-[#333a47] px-3 py-[6px] rounded-[7px]">{value}</div>
  </div>
);

export const Toggle: React.FC<{ on: boolean; onToggle?: () => void; interactive?: boolean; className?: string }> = ({
  on,
  onToggle,
  interactive = true,
  className = '',
}) => (
  <div
    onClick={interactive ? onToggle : undefined}
    className={`w-[34px] h-[19px] rounded-[10px] relative cursor-pointer transition-[background-color] duration-150 flex-shrink-0 ${
      on ? 'bg-[#1f9d6f]' : 'bg-[#31343b]'
    } ${className}`}
  >
    <div
      className={`w-[15px] h-[15px] rounded-full bg-[#f0f2f6] absolute top-[2px] transition-[left] duration-150 ${
        on ? 'left-[17px]' : 'left-[2px]'
      }`}
    />
  </div>
);

export const SearchInput: React.FC<React.InputHTMLAttributes<HTMLInputElement>> = ({ className = '', ...rest }) => (
  <div className="relative">
    <input
      {...rest}
      className={`w-full bg-[#333a47] border-none rounded-[8px] py-[9px] pl-8 pr-3 text-[#e7e9ee] text-[13px] font-sora outline-none placeholder:text-[#55606e] ${className}`}
    />
    <span className="absolute left-[10px] top-1/2 -translate-y-1/2 text-[#6b7280] text-[13px] pointer-events-none">⌕</span>
  </div>
);

export const Select: React.FC<React.SelectHTMLAttributes<HTMLSelectElement>> = ({ className = '', children, ...rest }) => (
  <select
    {...rest}
    className={`appearance-none bg-[#333a47] border-none rounded-[7px] px-2 py-[7px] text-[#b6bbc4] text-[12px] font-sora outline-none cursor-pointer ${className}`}
  >
    {children}
  </select>
);
