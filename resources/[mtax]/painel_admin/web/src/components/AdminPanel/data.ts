import type { AclGroup, Ban, Player, Resource, ServerSettings, TabName } from './types';

export const PLAYERS: Player[] = [
  { id: 0, name: 'netinhoresende', accountName: 'netinhoresende', groups: ['Admin', 'DevGroup'], acDetected: 'None', ip: '201.34.x.x', serial: '5A2F9C1B3D4E5F6A7B8C9D0E1F2A3B4C', version: '0.3.7-R2', frozen: false, muted: false, jetpack: false, health: 87, armour: 40, skin: 'CJ', weapon: 'Deagle', money: 12500, ping: 34, area: 'Los Santos', pos: '1542.2, -1678.4, 13.5', dimension: 0, interior: 0, vehicle: 'Sultan', vehicleHealth: 76 },
  { id: 1, name: 'Vortex_Malone', accountName: 'Vortex_Malone', groups: ['Moderador'], acDetected: 'None', ip: '187.12.x.x', serial: '9F1A2B3C4D5E6F7A8B9C0D1E2F3A4B5C', version: '0.3.7-R2', frozen: false, muted: false, jetpack: false, health: 100, armour: 100, skin: 'SWAT', weapon: 'M4', money: 5400, ping: 61, area: 'San Fierro', pos: '-2103.8, 341.1, 35.2', dimension: 0, interior: 0, vehicle: 'None', vehicleHealth: 0 },
  { id: 2, name: 'ShadowByte', accountName: 'ShadowByte', groups: [], acDetected: 'speedhack', ip: '190.88.x.x', serial: '1A2B3C4D5E6F7A8B9C0D1E2F3A4B5C6D', version: '0.3.7-R2', frozen: false, muted: false, jetpack: false, health: 54, armour: 0, skin: 'Triad', weapon: 'AK-47', money: 890, ping: 88, area: 'Las Venturas', pos: '2015.6, 1042.7, 10.8', dimension: 0, interior: 5, vehicle: 'NRG-500', vehicleHealth: 92 },
  { id: 3, name: 'QuickSilver92', accountName: 'Guest', groups: [], acDetected: 'None', ip: '177.45.x.x', serial: '4D5E6F7A8B9C0D1E2F3A4B5C6D7E8F9A', version: '0.3.7-R2', frozen: false, muted: false, jetpack: false, health: 100, armour: 60, skin: 'Ballas', weapon: 'None', money: 0, ping: 45, area: 'Los Santos', pos: '1204.4, -1893.0, 26.0', dimension: 0, interior: 0, vehicle: 'None', vehicleHealth: 0 },
];

export const OTHER_TABS: { label: Exclude<TabName, 'Players'>; icon: string }[] = [
  { label: 'Resources', icon: '🧩' },
  { label: 'Server', icon: '🖥️' },
  { label: 'Bans', icon: '🚫' },
];

export const MOD_LABELS = ['Kick', 'Ban', 'Mute', 'Freeze'];
export const DANGER_MOD_LABELS = ['Kick', 'Ban', 'Mute', 'Freeze'];

export const SET_LABELS = ['Health', 'Armour', 'Skin', 'Money'];

export const VEHICLE_LABELS = ['Repair', 'Explode', 'Destroy', 'Customize'];
export const DANGER_VEHICLE_LABELS = ['Explode', 'Destroy'];

export const ACL_GROUPS: AclGroup[] = [
  { name: 'Everyone', objects: [] },
  { name: 'Moderador', objects: [] },
  { name: 'SuperModerador', objects: [] },
  { name: 'Admin', objects: ['user.lil_Toady'] },
  { name: 'Console', objects: [] },
  { name: 'RPC', objects: [] },
  { name: 'MapEditor', objects: [] },
  { name: 'raceACLGroup', objects: [] },
  { name: 'DevGroup', objects: ['resource.painel_admin'] },
];

export const SERVER_SETTINGS: ServerSettings = { password: '', weatherId: 0, serverName: 'Server Development - Hyper Scripts', onlinePlayers: 1, maxPlayers: 32 };

export const BANS: Ban[] = [
  { id: 0, name: 'ToxicPlayer99', ip: '201.34.x.x', serial: '9F1A2B3C', by: 'lil_Toady', date: '2026-06-12' },
  { id: 1, name: 'CheatKing', ip: '187.12.x.x', serial: '4D5E6F7A', by: 'dev_ray', date: '2026-06-18' },
  { id: 2, name: 'GhostRunner', ip: '190.88.x.x', serial: '1A2B3C4D', by: 'lil_Toady', date: '2026-07-02' },
];

// GTA:SA weather IDs are engine-defined constants (not MTAX-specific) — used only for display.
export const WEATHER_NAMES: Record<number, string> = {
  0: 'Blue Sky, Sunny',
  1: 'Cloudy',
  2: 'Rainy',
  3: 'Foggy',
  4: 'Rainy (Extra Sunny)',
  8: 'Hazy Desert',
  9: 'Sandstorm',
  10: 'Sunny (Countryside)',
  17: 'Stormy',
  18: 'Foggy (Dense)',
  19: 'Overcast',
  28: 'Sunny (San Fierro)',
  33: 'Sunny (Las Venturas)',
};

export const getWeatherLabel = (id: number) => WEATHER_NAMES[id] ?? 'Unknown';

// Every GTA:SA vehicle model ID (400-611, wiki.multitheftauto.com/wiki/Vehicle_IDs) —
// the <select> value IS the numeric id, sent straight to createVehicle() server-side,
// so there's no name-string lookup table to keep in sync/get wrong.
export const VEHICLE_MODEL_IDS: Record<string, number> = {
  Landstalker: 400, Bravura: 401, Buffalo: 402, Linerunner: 403, Perennial: 404,
  Sentinel: 405, Dumper: 406, 'Fire Truck': 407, Trashmaster: 408, Stretch: 409,
  Manana: 410, Infernus: 411, Voodoo: 412, Pony: 413, Mule: 414,
  Cheetah: 415, Ambulance: 416, Leviathan: 417, Moonbeam: 418, Esperanto: 419,
  Taxi: 420, Washington: 421, Bobcat: 422, 'Mr. Whoopee': 423, 'BF Injection': 424,
  Hunter: 425, Premier: 426, Enforcer: 427, Securicar: 428, Banshee: 429,
  Predator: 430, Bus: 431, Rhino: 432, Barracks: 433, Hotknife: 434,
  'Trailer 1': 435, Previon: 436, Coach: 437, Cabbie: 438, Stallion: 439,
  Rumpo: 440, 'RC Bandit': 441, Romero: 442, Packer: 443, Monster: 444,
  Admiral: 445, Squalo: 446, Seasparrow: 447, Pizzaboy: 448, Tram: 449,
  'Trailer 2': 450, Turismo: 451, Speeder: 452, Reefer: 453, Tropic: 454,
  Flatbed: 455, Yankee: 456, Caddy: 457, Solair: 458, "Berkley's RC Van": 459,
  Skimmer: 460, 'PCJ-600': 461, Faggio: 462, Freeway: 463, 'RC Baron': 464,
  'RC Raider': 465, Glendale: 466, Oceanic: 467, Sanchez: 468, Sparrow: 469,
  Patriot: 470, Quadbike: 471, Coastguard: 472, Dinghy: 473, Hermes: 474,
  Sabre: 475, Rustler: 476, 'ZR-350': 477, Walton: 478, Regina: 479,
  Comet: 480, BMX: 481, Burrito: 482, Camper: 483, Marquis: 484,
  Baggage: 485, Dozer: 486, Maverick: 487, 'News Chopper': 488, Rancher: 489,
  'FBI Rancher': 490, Virgo: 491, Greenwood: 492, Jetmax: 493, 'Hotring Racer': 494,
  Sandking: 495, 'Blista Compact': 496, 'Police Maverick': 497, Boxville: 498, Benson: 499,
  Mesa: 500, 'RC Goblin': 501, 'Hotring Racer 2': 502, 'Hotring Racer 3': 503, 'Bloodring Banger': 504,
  'Rancher Lure': 505, 'Super GT': 506, Elegant: 507, Journey: 508, Bike: 509,
  'Mountain Bike': 510, Beagle: 511, Cropduster: 512, Stuntplane: 513, Tanker: 514,
  Roadtrain: 515, Nebula: 516, Majestic: 517, Buccaneer: 518, Shamal: 519,
  Hydra: 520, 'FCR-900': 521, 'NRG-500': 522, HPV1000: 523, 'Cement Truck': 524,
  Towtruck: 525, Fortune: 526, Cadrona: 527, 'FBI Truck': 528, Willard: 529,
  Forklift: 530, Tractor: 531, 'Combine Harvester': 532, Feltzer: 533, Remington: 534,
  Slamvan: 535, Blade: 536, Freight: 537, Streak: 538, Vortex: 539,
  Vincent: 540, Bullet: 541, Clover: 542, Sadler: 543, 'Fire Truck Ladder': 544,
  Hustler: 545, Intruder: 546, Primo: 547, Cargobob: 548, Tampa: 549,
  Sunrise: 550, Merit: 551, 'Utility Van': 552, Nevada: 553, Yosemite: 554,
  Windsor: 555, 'Monster 2': 556, 'Monster 3': 557, Uranus: 558, Jester: 559,
  Sultan: 560, Stratum: 561, Elegy: 562, Raindance: 563, 'RC Tiger': 564,
  Flash: 565, Tahoma: 566, Savanna: 567, Bandito: 568, 'Freight Train Flatbed': 569,
  'Streak Train Trailer': 570, Kart: 571, Mower: 572, Dune: 573, Sweeper: 574,
  Broadway: 575, Tornado: 576, 'AT-400': 577, 'DFT-30': 578, Huntley: 579,
  Stafford: 580, 'BF-400': 581, Newsvan: 582, Tug: 583, 'Tanker Trailer': 584,
  Emperor: 585, Wayfarer: 586, Euros: 587, Hotdog: 588, Club: 589,
  'Box Freight': 590, 'Trailer 3': 591, Andromada: 592, Dodo: 593, 'RC Cam': 594,
  Launch: 595, 'Police LS': 596, 'Police SF': 597, 'Police LV': 598, 'Police Ranger': 599,
  Picador: 600, 'S.W.A.T.': 601, Alpha: 602, Phoenix: 603, 'Glendale Damaged': 604,
  'Sadler Damaged': 605, 'Baggage Trailer (Covered)': 606, 'Baggage Trailer (Open)': 607, 'Stairs Trailer': 608, 'Boxville Mission': 609,
  'Farm Trailer': 610, 'Street Cleaner Trailer': 611,
};

// Every GTA:SA weapon ID (wiki.multitheftauto.com/wiki/Weapon) — the <select>
// value IS the numeric id, sent straight to giveWeapon() server-side.
export const WEAPON_IDS: Record<string, number> = {
  'Brass Knuckles': 1, 'Golf Club': 2, Nightstick: 3, Knife: 4, 'Baseball Bat': 5,
  Shovel: 6, 'Pool Cue': 7, Katana: 8, Chainsaw: 9, Dildo: 10,
  'Purple Dildo': 11, Vibrator: 12, 'Silver Vibrator': 13, Flower: 14, Cane: 15,
  Grenade: 16, 'Tear Gas': 17, Molotov: 18, 'Colt 45': 22, 'Silenced 9mm': 23,
  'Desert Eagle': 24, Shotgun: 25, 'Sawn-off Shotgun': 26, 'Combat Shotgun': 27, Uzi: 28,
  MP5: 29, 'AK-47': 30, M4: 31, 'Tec-9': 32, 'Country Rifle': 33,
  'Sniper Rifle': 34, 'Rocket Launcher': 35, 'Rocket Launcher HS': 36, Flamethrower: 37, Minigun: 38,
  'Satchel Charge': 39, Detonator: 40, 'Spray Can': 41, 'Fire Extinguisher': 42, Camera: 43,
  'Night Vision Goggles': 44, 'Infrared Goggles': 45, Parachute: 46,
};

// A handful of well-known named interiors (wiki.multitheftauto.com/wiki/Interior_IDs)
// used by the Players tab's interior teleport list.
export const INTERIOR_LOCATIONS: { name: string; x: number; y: number; z: number; interior: number }[] = [
  { name: 'Base (Outside)', x: 0, y: 0, z: 5, interior: 0 },
  { name: 'LSPD HQ', x: 246.451, y: 65.586, z: 1003.641, interior: 6 },
  { name: 'LVPD HQ', x: 289.7703, y: 171.746, z: 1007.179, interior: 3 },
  { name: 'SFPD HQ', x: 246.441, y: 112.164, z: 1003.219, interior: 10 },
  { name: 'Ammu-Nation 1', x: 289.787, y: -35.719, z: 1003.516, interior: 1 },
  { name: 'Ammu-Nation 2', x: 285.8, y: -84.547, z: 1001.539, interior: 4 },
  { name: 'Ammu-Nation 3', x: 297.446, y: -109.968, z: 1001.516, interior: 6 },
  { name: 'Ammu-Nation 4', x: 317.238, y: -168.052, z: 999.593, interior: 6 },
  { name: 'Ammu-Nation 5', x: 315.385, y: -142.242, z: 999.601, interior: 7 },
  { name: "Caligula's Casino", x: 2235.2524, y: 1708.5146, z: 1010.6129, interior: 1 },
  { name: 'Four Dragons Casino', x: 2009.414, y: 1017.899, z: 994.468, interior: 10 },
  { name: 'The Casino', x: 1132.945, y: -8.675, z: 1000.68, interior: 12 },
  { name: 'Ganton Gym', x: 768.0793, y: 5.8606, z: 1000.716, interior: 5 },
  { name: "Cobra Marital Arts Gym", x: 774.087, y: -47.983, z: 1000.586, interior: 6 },
  { name: 'Below the Belt Gym', x: 774.243, y: -76.009, z: 1000.654, interior: 7 },
  { name: "Reece's Barbershop", x: 411.6259, y: -21.4332, z: 1001.8046, interior: 2 },
  { name: "Gay Gordo's Barbershop", x: 418.653, y: -82.639, z: 1001.805, interior: 3 },
  { name: "Macisla's Barbershop", x: 411.641, y: -51.846, z: 1001.898, interior: 12 },
];

export const RESOURCES: Resource[] = [
  { id: 0, name: '(Mod)TXD-Arvores', state: 'running', author: 'lil_Toady', version: '1.2.0', fullName: 'Mod TXD Árvores' },
  { id: 1, name: '(Mod)TXD-Pack-Textures', state: 'running', author: 'lil_Toady', version: '1.0.4', fullName: 'Mod TXD Pack Textures' },
  { id: 2, name: '(Trust)Aeroporto-LS', state: 'loaded', author: 'equipe-mapas', version: '2.1.0', fullName: 'Aeroporto Los Santos' },
  { id: 3, name: '(Trust)Apartamentos', state: 'loaded', author: 'equipe-mapas', version: '1.3.2', fullName: 'Sistema de Apartamentos' },
  { id: 4, name: '(Trust)Casino', state: 'loaded', author: 'equipe-mapas', version: '1.0.0', fullName: 'Casino' },
  { id: 5, name: '(Trust)Casino-System', state: 'loaded', author: 'dev_ray', version: '3.4.1', fullName: 'Sistema do Casino' },
  { id: 6, name: '(Trust)Hospital-LS', state: 'loaded', author: 'equipe-mapas', version: '1.1.0', fullName: 'Hospital Los Santos' },
  { id: 7, name: '+veiculos', state: 'loaded', author: 'lil_Toady', version: '4.0.0', fullName: 'Veículos Adicionais' },
  { id: 8, name: 'APIShop', state: 'loaded', author: 'dev_ray', version: '2.0.1', fullName: 'API de Loja' },
  { id: 9, name: 'ASAAS_API', state: 'loaded', author: 'dev_ray', version: '1.0.0', fullName: 'Integração ASAAS' },
  { id: 10, name: 'Arvore', state: 'loaded', author: 'lil_Toady', version: '1.0.0', fullName: 'Sistema de Árvore' },
  { id: 11, name: 'Backup_Inv', state: 'loaded', author: 'dev_ray', version: '1.5.0', fullName: 'Backup de Inventário' },
  { id: 12, name: 'Blur', state: 'loaded', author: 'lil_Toady', version: '1.0.0', fullName: 'Efeito Blur' },
];
