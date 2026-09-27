import { createContext, useContext } from 'react';
import type { Bookmark, BootPayload, ClothesGroup, LiveState, Options } from './types';

export interface Freeroam {
  boot: BootPayload;
  options: Options;
  state: LiveState | null;
  bookmarks: Bookmark[];
  clothes: ClothesGroup[] | null;
  isOpen: (id: string) => boolean;
  open: (id: string) => void;
  close: (id: string) => void;
  toggle: (id: string) => void;
}

export const FreeroamContext = createContext<Freeroam | null>(null);

export const useFreeroam = () => {
  const value = useContext(FreeroamContext);
  if (!value) throw new Error('useFreeroam outside FreeroamContext');
  return value;
};
