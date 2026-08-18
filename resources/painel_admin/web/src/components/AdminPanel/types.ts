export interface Player {
  id: number;
  name: string;
  accountName: string;
  groups: string[];
  acDetected: string;
  ip: string;
  serial: string;
  version: string;
  frozen: boolean;
  muted: boolean;
  jetpack: boolean;
  health: number;
  armour: number;
  skin: string;
  weapon: string;
  money: number;
  ping: number;
  area: string;
  pos: string;
  dimension: number;
  interior: number;
  vehicle: string;
  vehicleHealth: number;
}

export interface VehicleUpgradeOption {
  id: number;
  name: string;
}

export interface VehicleUpgradeSlot {
  slot: number;
  name: string;
  current: number;
  options: VehicleUpgradeOption[];
}

export interface VehicleCustomization {
  ok: boolean;
  message?: string;
  vehicleName: string;
  slots: VehicleUpgradeSlot[];
  colors: number[];
  paintjob: number;
  plate: string;
  headlight: { r: number; g: number; b: number };
}

export type ResourceState = 'running' | 'loaded' | 'stopped';

export interface Resource {
  id: number;
  name: string;
  state: ResourceState;
  author: string;
  version: string;
  fullName: string;
}

export interface Ban {
  id: number;
  name: string;
  ip: string;
  serial: string;
  by: string;
  date: string;
}

export interface AclGroup {
  name: string;
  objects: string[];
}

export interface ServerSettings {
  password: string;
  weatherId: number;
  serverName: string;
  onlinePlayers: number;
  maxPlayers: number;
}

export type TabName = 'Players' | 'Resources' | 'Server' | 'Bans';

export interface TogglesState {
  hideSensitive: boolean;
}

export interface FieldDef {
  label: string;
  value: string;
}
