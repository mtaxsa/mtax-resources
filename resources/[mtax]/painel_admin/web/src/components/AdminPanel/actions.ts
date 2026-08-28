import { fetchNui } from '../../utils/fetchNui';

export type ModerationAction = 'kick' | 'ban' | 'mute' | 'freeze';
export type PlayerStat = 'health' | 'armour' | 'skin' | 'time' | 'money';
export type VehicleMaintenanceAction = 'repair' | 'explode' | 'destroy';
export type VehicleCustomizeAction = 'setUpgrades' | 'upgradeAll' | 'removeAll' | 'setColors' | 'setPaintjob' | 'setPlate' | 'setHeadlightColor';
export type ResourceLifecycleAction = 'start' | 'restart' | 'stop';
export type BanRowAction = 'details' | 'unban' | 'unbanIp' | 'unbanSerial';
export type AclGroupAction = 'createGroup' | 'destroyGroup' | 'addObject' | 'removeObject';

/**
 * Every call here is a `registerNuiCallback` name that client.lua listens
 * for (see client/client.lua). Client relays each one to server.lua over
 * `triggerServerEvent`, which is where the actual game state changes happen.
 */
export const AdminActions = {
  closePanel: () => fetchNui('closePanel'),
  getPlayers: () => fetchNui('getPlayers'),

  moderatePlayer: (id: number, action: ModerationAction) => fetchNui('moderatePlayer', { id, action }),
  spectatePlayer: (id: number) => fetchNui('spectatePlayer', { id }),
  slapPlayer: (id: number, amount: number) => fetchNui('slapPlayer', { id, amount }),
  shoutPlayer: (id: number) => fetchNui('shoutPlayer', { id }),
  setPlayerStat: (id: number, stat: PlayerStat, value: string) => fetchNui('setPlayerStat', { id, stat, value }),
  resetPlayerStats: (id: number) => fetchNui('resetPlayerStats', { id }),
  givePlayerWeapon: (id: number, weaponId: number) => fetchNui('givePlayerWeapon', { id, weapon: weaponId }),
  givePlayerVehicle: (id: number, modelId: number) => fetchNui('givePlayerVehicle', { id, model: modelId }),
  givePlayerJetpack: (id: number) => fetchNui('givePlayerJetpack', { id }),
  warpToPlayer: (id: number) => fetchNui('warpToPlayer', { id }),
  warpPlayerToMe: (id: number) => fetchNui('warpPlayerToMe', { id }),
  vehicleMaintenance: (id: number, action: VehicleMaintenanceAction) => fetchNui('vehicleMaintenance', { id, action }),
  setVehicleDimension: (id: number, dimension: string) => fetchNui('setVehicleDimension', { id, dimension }),
  teleportPlayerToInterior: (id: number, x: number, y: number, z: number, interior: number) =>
    fetchNui('teleportPlayerToInterior', { id, x, y, z, interior }),
  getVehicleCustomization: (id: number) => fetchNui('getVehicleCustomization', { id }),
  vehicleCustomizeAction: (id: number, action: VehicleCustomizeAction, payload?: Record<string, unknown>) =>
    fetchNui('vehicleCustomizeAction', { id, action, ...payload }),

  getResources: () => fetchNui('getResources'),
  resourceLifecycle: (name: string, action: ResourceLifecycleAction) => fetchNui('resourceLifecycle', { name, action }),
  refreshResources: () => fetchNui('refreshResources'),
  executeCommand: (command: string, scope: 'client' | 'server') => fetchNui('executeCommand', { command, scope }),
  getActionLog: () => fetchNui('getActionLog'),

  getServerSettings: () => fetchNui('getServerSettings'),
  setServerPassword: (password: string) => fetchNui('setServerPassword', { password }),
  setWeather: (id: number, blended: boolean) => fetchNui('setWeather', { id, blended }),
  setTime: (value: string) => fetchNui('setTime', { value }),
  setGravity: (value: string) => fetchNui('setGravity', { value }),
  setGameSpeed: (value: string) => fetchNui('setGameSpeed', { value }),
  setWaveHeight: (value: string) => fetchNui('setWaveHeight', { value }),
  setFpsLimit: (value: string) => fetchNui('setFpsLimit', { value }),
  sendWelcomeMessage: (message: string) => fetchNui('sendWelcomeMessage', { message }),
  shutdownServer: () => fetchNui('shutdownServer'),
  clearChat: () => fetchNui('clearChat'),

  getBans: () => fetchNui('getBans'),
  searchBans: (query: string, type: 'Name' | 'IP' | 'Serial') => fetchNui('searchBans', { query, type }),
  banRowAction: (id: number, action: BanRowAction) => fetchNui('banRowAction', { id, action }),
  banByField: (id: number, field: 'ip' | 'serial') => fetchNui('banByField', { id, field }),
  refreshBans: () => fetchNui('refreshBans'),

  getAclGroups: () => fetchNui('getAclGroups'),
  aclGroupAction: (action: AclGroupAction, group: string | null, value?: string) =>
    fetchNui('aclGroupAction', { action, group, value }),
};
