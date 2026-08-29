import { useCallback, useEffect, useState } from 'react';
import type { Corner, Settings } from './types';

const STORAGE_KEY = 'mtax-chat-settings';

export const DEFAULT_SETTINGS: Settings = {
  x: null,
  y: null,
  timestamps: null,
  notifications: true,
  opacity: 1,
  colors: {},
};

export const WIDGET_WIDTH = 520;
export const WIDGET_HEIGHT = 460;
const MARGIN = 24;

export const cornerPosition = (corner: Corner) => {
  switch (corner) {
    case 'top-right':
      return { x: Math.max(MARGIN, window.innerWidth - WIDGET_WIDTH - MARGIN), y: MARGIN };
    case 'bottom-left':
      return { x: MARGIN, y: Math.max(MARGIN, window.innerHeight - WIDGET_HEIGHT - MARGIN) };
    default:
      return { x: MARGIN, y: MARGIN };
  }
};

const read = (): Settings => {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return DEFAULT_SETTINGS;
    return { ...DEFAULT_SETTINGS, ...JSON.parse(raw) };
  } catch {
    return DEFAULT_SETTINGS;
  }
};

export const useSettings = () => {
  const [settings, setSettings] = useState<Settings>(read);

  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(settings));
    } catch { }
  }, [settings]);

  const patch = useCallback((next: Partial<Settings>) => {
    setSettings((current) => ({ ...current, ...next }));
  }, []);

  const setColor = useCallback((kind: string, color: string | null) => {
    setSettings((current) => {
      const colors = { ...current.colors };
      if (color) colors[kind] = color;
      else delete colors[kind];
      return { ...current, colors };
    });
  }, []);

  const reset = useCallback(() => setSettings(DEFAULT_SETTINGS), []);

  return { settings, patch, setColor, reset };
};
