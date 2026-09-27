import animations from './animations.json';
import interiors from './interiors.json';
import skins from './skins.json';
import stats from './stats.json';
import vehicles from './vehicles.json';
import walks from './walks.json';
import weapons from './weapons.json';
import weather from './weather.json';

export interface Named {
  id: number;
  name: string;
  group?: string;
}

export interface Skin extends Named {
  keywords?: string;
}

export interface Animation {
  name: string;
  group: string;
}

export interface Interior {
  name: string;
  world: number;
  x: number;
  y: number;
  z: number;
}

export interface Preset {
  id: number;
  name: string;
  value: number;
}

export const DATA = {
  animations: animations as Animation[],
  interiors: interiors as Interior[],
  skins: skins as Skin[],
  stats: stats as Named[],
  vehicles: vehicles as Named[],
  walks: walks as Named[],
  weapons: weapons as Named[],
  weather: weather as Named[],
};

export const FIGHT_STYLES: Named[] = [
  { id: 4, name: '@catalog.fight.default' },
  { id: 5, name: '@catalog.fight.boxing' },
  { id: 6, name: 'Kung Fu' },
  { id: 7, name: '@catalog.fight.knee' },
  { id: 15, name: 'Grab & Kick' },
  { id: 16, name: '@catalog.fight.elbow' },
];

export const GRAVITY_PRESETS: Preset[] = [
  { id: 1, name: '@catalog.gravity.moon', value: 0.001 },
  { id: 2, name: '@catalog.gravity.low', value: 0.004 },
  { id: 3, name: '@catalog.gravity.normal', value: 0.008 },
  { id: 4, name: '@catalog.gravity.high', value: 0.015 },
  { id: 5, name: '@catalog.gravity.heavy', value: 0.03 },
];

export const SPEED_PRESETS: Preset[] = [
  { id: 1, name: '@catalog.speed.very_slow', value: 0.25 },
  { id: 2, name: '@catalog.speed.slow', value: 0.5 },
  { id: 3, name: '@catalog.speed.normal', value: 1 },
  { id: 4, name: '@catalog.speed.fast', value: 1.5 },
  { id: 5, name: '@catalog.speed.very_fast', value: 2 },
  { id: 6, name: '@catalog.speed.extreme', value: 3 },
];

export const TIME_PRESETS: Preset[] = [
  { id: 1, name: '@catalog.time.midnight', value: 0 },
  { id: 2, name: '@catalog.time.dawn', value: 5 },
  { id: 3, name: '@catalog.time.morning', value: 9 },
  { id: 4, name: '@catalog.time.noon', value: 12 },
  { id: 5, name: '@catalog.time.afternoon', value: 15 },
  { id: 6, name: '@catalog.time.dusk', value: 20 },
  { id: 7, name: '@catalog.time.night', value: 22 },
];

export const PAINTJOBS: Named[] = [
  { id: 0, name: '@catalog.paintjob.0' },
  { id: 1, name: '@catalog.paintjob.1' },
  { id: 2, name: '@catalog.paintjob.2' },
  { id: 3, name: '@catalog.paintjob.remove' },
];
