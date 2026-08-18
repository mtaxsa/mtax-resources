import React from 'react';
import { OTHER_TABS } from './data';
import type { TabName } from './types';
import { SearchInput } from './ui';

interface SidebarProps {
  activeTab: TabName;
  onTabChange: (tab: TabName) => void;
  search: string;
  onSearchChange: (value: string) => void;
}

const navRowClasses = (active: boolean) =>
  `flex items-center gap-[9px] px-[10px] py-[9px] rounded-[8px] cursor-pointer text-[13px] ${
    active ? 'bg-[#333a47] text-[#f0f2f6] font-semibold' : 'bg-transparent text-[#9aa1ad] font-medium'
  }`;

export const Sidebar: React.FC<SidebarProps> = ({ activeTab, onTabChange, search, onSearchChange }) => (
  <div className="w-[224px] flex-shrink-0 bg-[#20252f] border-r border-white/5 px-[14px] py-[18px] flex flex-col gap-[18px]">
    <SearchInput value={search} onChange={(e) => onSearchChange(e.target.value)} placeholder="Search player" />

    <div>
      <div className="text-[#5c6270] text-[11px] font-semibold tracking-[0.4px] px-2 pb-2">Panel</div>
      <div onClick={() => onTabChange('Players')} className={navRowClasses(activeTab === 'Players')}>
        <span className="text-[14px]">👥</span> Players
      </div>
    </div>

    <div>
      <div className="text-[#5c6270] text-[11px] font-semibold tracking-[0.4px] px-2 pb-2">Tools</div>
      <div className="flex flex-col gap-[2px]">
        {OTHER_TABS.map((tab) => (
          <div key={tab.label} onClick={() => onTabChange(tab.label)} className={navRowClasses(activeTab === tab.label)}>
            <span className="text-[14px]">{tab.icon}</span> {tab.label}
          </div>
        ))}
      </div>
    </div>
  </div>
);
