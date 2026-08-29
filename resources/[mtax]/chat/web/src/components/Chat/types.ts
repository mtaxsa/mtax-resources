export type MessageForm = 'said' | 'action' | 'plain';

export interface ChatType {
  label: string;
  color: string;
  form: MessageForm;
  fade?: number;
}

export interface Suggestion {
  name: string;
  params: string;
  help: string;
}

export interface BootPayload {
  types: Record<string, ChatType>;
  tabs: string[];
  defaultTab: string;
  suggestions: Suggestion[];
  stickers: string[];
  history: number;
  maxLength: number;
  hideAfter: number;
  timestamps: boolean;
  openKey: string;
}

export interface ColorRun {
  text: string;
  color: string;
}

export interface ChatMessage {
  id?: number;
  kind: string;
  name?: string;
  pid?: number;
  text: string;
  sticker?: string;
  time?: string;
  note?: string;
  color?: string;
  segments?: ColorRun[];
  three?: boolean;
  localOnly?: boolean;
}

export interface HistoryRow extends ChatMessage {
  key: number;
  at: number;
}

export interface RosterEntry {
  id: number;
  name: string;
}

export interface SessionPayload {
  id: number;
  roster: RosterEntry[];
  enabled: boolean;
  admin: boolean;
}

export interface WorldLabel {
  i: number;
  k: string;
  n: string;
  t: string;
  s?: string;
  x: number;
  y: number;
  o: number;
  a: number;
  z: number;
}

export type Corner = 'top-left' | 'top-right' | 'bottom-left';

export interface Settings {
  x: number | null;
  y: number | null;
  timestamps: boolean | null;
  notifications: boolean;
  opacity: number;
  colors: Record<string, string>;
}

export const asArray = <T,>(value: unknown): T[] => (Array.isArray(value) ? (value as T[]) : []);
