export interface Keys {
  panel: string;
  map: string;
  jetpack: string;
}

export interface BootPayload {
  language: string;
  keys: Keys;
}

export interface Options {
  kill?: boolean;
  jetpack?: boolean;
  warp?: boolean;
  removeHex?: boolean;
  gamespeed?: { enabled?: boolean; min?: number; max?: number };
  gui?: { antiram?: boolean; disablewarp?: boolean; disableknife?: boolean };
  [key: string]: unknown;
}

export interface Bookmark {
  name: string;
  x: number;
  y: number;
  z: number;
  interior: number;
  dimension: number;
}

export interface SessionPayload {
  options: Options;
  bookmarks: Bookmark[];
}

export interface LiveState {
  x: number;
  y: number;
  z: number;
  interior: number;
  dimension: number;
  vehicle: string | false;
  driver: boolean;
  health: number;
  lights: number;
  jetpack: boolean;
  bike: boolean;
  warping: boolean;
  knifing: boolean;
  ghostmode: boolean;
  frozen: boolean;
  hour: number;
  minute: number;
  skin: number;
  gravity: number;
  speed: number;
  fight: number;
  dead: boolean;
}

export type ToastKind = 'info' | 'success' | 'warning' | 'error';

export interface ToastPayload {
  key: string;
  vars?: Record<string, string | number>;
  kind?: ToastKind;
}

export interface Toast extends ToastPayload {
  id: number;
}

export interface ClothesGroup {
  type: number;
  name: string;
  items: { texture: string; model: string }[];
}

export interface PlayerEntry {
  key: string;
  name: string;
  vehicle: string | false;
  distance: number | false;
  blocked: boolean;
}

export interface Blip {
  x: number;
  y: number;
  key: string;
  name: string;
  me: boolean;
}

export interface Upgrade {
  id: number;
  slot: string;
  installed: boolean;
}

export const asArray = <T,>(value: unknown): T[] => (Array.isArray(value) ? (value as T[]) : []);
