import React, { useEffect, useMemo, useState } from 'react';
import {
  DATA,
  FIGHT_STYLES,
  GRAVITY_PRESETS,
  PAINTJOBS,
  SPEED_PRESETS,
  TIME_PRESETS,
  type Named,
  type Preset,
} from '../data';
import { usePoll } from '../hooks/usePoll';
import { useI18n } from '../i18n';
import { fetchNui } from '../utils/fetchNui';
import { Browser, type Row } from './Browser';
import { useFreeroam } from './context';
import { asArray, type ClothesGroup, type PlayerEntry, type Upgrade } from './types';

export interface ToolProps {
  active: boolean;
}

const nui = (name: string, data?: unknown) => {
  fetchNui(name, data);
};

const pad = (value: number) => String(value).padStart(2, '0');

interface IdRow extends Row {
  id: number;
}

const namedRows = (list: Named[], right = true): IdRow[] =>
  list.map((item) => ({
    key: String(item.id),
    id: item.id,
    name: item.name,
    group: item.group,
    search: `${item.name} ${item.group ?? ''} ${item.id}`.toLowerCase(),
    right: right ? `#${item.id}` : undefined,
  }));

interface PresetRow extends Row {
  value: number;
}

const presetRows = (list: Preset[], right: (preset: Preset) => string, field: (preset: Preset) => Record<string, string>): PresetRow[] =>
  list.map((preset) => ({
    key: String(preset.id),
    name: preset.name,
    value: preset.value,
    right: right(preset),
    fields: field(preset),
  }));

/// Player

export const SkinsTool: React.FC<ToolProps> = ({ active }) => {
  const rows = useMemo<IdRow[]>(
    () =>
      DATA.skins.map((skin) => ({
        key: String(skin.id),
        id: skin.id,
        name: skin.name,
        group: skin.group,
        search: `${skin.name} ${skin.group ?? ''} ${skin.id} ${skin.keywords ?? ''}`.toLowerCase(),
        right: `#${skin.id}`,
      })),
    []
  );

  return (
    <Browser
      id="skins"
      active={active}
      rows={rows}
      search="@search.skins"
      actions={[{ label: '@action.use_skin', variant: 'primary', run: (row) => nui('skin', { id: row?.id }) }]}
    />
  );
};

interface AnimationRow extends Row {
  block: string;
}

export const AnimationsTool: React.FC<ToolProps> = ({ active }) => {
  const rows = useMemo<AnimationRow[]>(
    () =>
      DATA.animations.map((animation) => ({
        key: `${animation.group}/${animation.name}`,
        name: animation.name,
        block: animation.group,
        group: animation.group,
        sub: animation.group,
        search: `${animation.name} ${animation.group}`.toLowerCase(),
      })),
    []
  );

  return (
    <Browser
      id="animations"
      active={active}
      rows={rows}
      search="@search.animations"
      actions={[
        { label: '@action.stop', free: true, run: () => nui('stopAnimation') },
        {
          label: '@action.play',
          variant: 'primary',
          run: (row) => row && nui('animation', { block: row.block, name: row.name }),
        },
      ]}
    />
  );
};

export const WeaponsTool: React.FC<ToolProps> = ({ active }) => {
  const rows = useMemo(() => namedRows(DATA.weapons), []);

  return (
    <Browser
      id="weapons"
      active={active}
      rows={rows}
      fields={[{ id: 'ammo', label: '@field.ammo', initial: '500', width: 84, max: 4 }]}
      actions={[
        {
          label: '@action.give_weapon',
          variant: 'primary',
          run: (row, values) => nui('weapon', { id: row?.id, ammo: Number(values.ammo) }),
        },
      ]}
    />
  );
};

interface ClothesRow extends Row {
  texture: string;
  model: string;
  type: number;
}

export const ClothesTool: React.FC<ToolProps> = ({ active }) => {
  const { clothes } = useFreeroam();
  const [fetched, setFetched] = useState<ClothesGroup[] | null>(null);
  const groups = clothes ?? fetched;

  useEffect(() => {
    fetchNui<{ groups?: ClothesGroup[] | false }>('clothes').then((reply) => {
      if (reply?.groups) setFetched(asArray<ClothesGroup>(reply.groups));
    });
  }, []);

  const rows = useMemo<ClothesRow[]>(
    () =>
      asArray<ClothesGroup>(groups).flatMap((group) =>
        asArray<ClothesGroup['items'][number]>(group.items).map((item) => ({
          key: `${group.type}:${item.texture}:${item.model}`,
          name: item.texture,
          sub: item.model,
          group: group.name,
          search: `${item.texture} ${item.model} ${group.name}`.toLowerCase(),
          texture: item.texture,
          model: item.model,
          type: group.type,
        }))
      ),
    [groups]
  );

  return (
    <Browser
      id="clothes"
      active={active}
      rows={rows}
      empty={groups ? '@common.nothing_found' : '@clothes.loading'}
      actions={[
        { label: '@action.remove_type', run: (row) => row && nui('unwear', { type: row.type }) },
        {
          label: '@action.wear',
          variant: 'primary',
          run: (row) => row && nui('wear', { texture: row.texture, model: row.model, type: row.type }),
        },
      ]}
    />
  );
};

export const StatsTool: React.FC<ToolProps> = ({ active }) => {
  const ids = useMemo(() => DATA.stats.map((stat) => stat.id), []);
  const reply = usePoll<{ values?: { id: number; value: number }[] }>('stats', 500, { values: [] }, { ids });

  const rows = useMemo<IdRow[]>(() => {
    const values = new Map(asArray<{ id: number; value: number }>(reply?.values).map((entry) => [entry.id, entry.value]));

    return namedRows(DATA.stats).map((row) => {
      const value = values.get(row.id);
      return {
        ...row,
        right: value === undefined ? undefined : String(value),
        tone: value === undefined ? undefined : value >= 1000 ? 'ok' : value <= 0 ? 'muted' : undefined,
      };
    });
  }, [reply]);

  const set = (row: IdRow | undefined, value: number | string) =>
    row && nui('stat', { id: row.id, value: Number(value), label: row.name });

  return (
    <Browser
      id="stats"
      active={active}
      rows={rows}
      fields={[{ id: 'value', label: '@field.value', initial: '1000', width: 84, max: 4 }]}
      actions={[
        { label: '@action.reset', run: (row) => set(row, 0) },
        { label: '@action.maximize', run: (row) => set(row, 1000) },
        { label: '@common.apply', variant: 'primary', run: (row, values) => set(row, values.value) },
      ]}
    />
  );
};

export const WalksTool: React.FC<ToolProps> = ({ active }) => {
  const rows = useMemo(() => namedRows(DATA.walks), []);

  return (
    <Browser
      id="walks"
      active={active}
      rows={rows}
      actions={[
        { label: '@action.restore', free: true, run: () => nui('walk', { id: 0 }) },
        { label: '@common.apply', variant: 'primary', run: (row) => nui('walk', { id: row?.id }) },
      ]}
    />
  );
};

export const FightStylesTool: React.FC<ToolProps> = ({ active }) => {
  const rows = useMemo(() => namedRows(FIGHT_STYLES, false), []);

  return (
    <Browser
      id="fightstyles"
      active={active}
      rows={rows}
      actions={[{ label: '@common.apply', variant: 'primary', run: (row) => nui('fight', { id: row?.id }) }]}
    />
  );
};

export const GravityTool: React.FC<ToolProps> = ({ active }) => {
  const rows = useMemo(
    () => presetRows(GRAVITY_PRESETS, (preset) => String(preset.value), (preset) => ({ value: String(preset.value) })),
    []
  );

  return (
    <Browser
      id="gravity"
      active={active}
      rows={rows}
      fields={[{ id: 'value', label: '@field.exact', initial: '0.008', width: 90 }]}
      actions={[
        { label: '@common.apply', variant: 'primary', free: true, run: (_, values) => nui('gravity', { value: Number(values.value) }) },
      ]}
    />
  );
};

interface PlayerRow extends Row {
  player: string;
}

export const PlayersTool: React.FC<ToolProps> = ({ active }) => {
  const reply = usePoll<{ players?: PlayerEntry[] }>('players', 700, {
    players: [
      { key: 'Maria', name: 'Maria Cortez', vehicle: 'Infernus', distance: 214, blocked: false },
      { key: 'Frank', name: 'Frank Hithock', vehicle: false, distance: 1380, blocked: true },
    ],
  });

  const rows = useMemo<PlayerRow[]>(
    () =>
      asArray<PlayerEntry>(reply?.players).map((player) => ({
        key: player.key,
        player: player.key,
        name: player.name,
        search: player.name.toLowerCase(),
        sub: player.vehicle || '@common.on_foot',
        right: player.distance === false ? undefined : `${player.distance}m`,
        tone: player.blocked ? 'muted' : undefined,
      })),
    [reply]
  );

  return (
    <Browser
      id="players"
      active={active}
      rows={rows}
      empty="@players.none_online"
      actions={[{ label: '@action.warp_player', variant: 'primary', run: (row) => row && nui('warp', { key: row.player }) }]}
    />
  );
};

interface BookmarkRow extends Row {
  index: number;
}

export const BookmarksTool: React.FC<ToolProps> = ({ active }) => {
  const { bookmarks } = useFreeroam();
  const { t } = useI18n();

  const rows = useMemo<BookmarkRow[]>(
    () =>
      bookmarks.map((mark, index) => ({
        key: `${index}:${mark.name}`,
        index: index + 1,
        name: mark.name,
        search: mark.name.toLowerCase(),
        right: t('bookmarks.position', {
          x: mark.x.toFixed(0),
          y: mark.y.toFixed(0),
          z: mark.z.toFixed(0),
          interior: mark.interior,
        }),
      })),
    [bookmarks, t]
  );

  return (
    <Browser
      id="bookmarks"
      active={active}
      rows={rows}
      empty="@bookmarks.empty"
      fields={[
        { id: 'name', label: '@field.name', initial: '', text: true, width: 190, max: 28, placeholder: '@bookmarks.name_placeholder' },
      ]}
      actions={[
        { label: '@action.delete', variant: 'danger', run: (row) => row && nui('bookmarkDelete', { index: row.index }) },
        { label: '@action.save_here', free: true, run: (_, values) => nui('bookmark', { name: values.name }) },
        { label: '@action.go_location', variant: 'primary', run: (row) => row && nui('bookmarkGo', { index: row.index }) },
      ]}
    />
  );
};

interface InteriorRow extends Row {
  world: number;
  x: number;
  y: number;
  z: number;
}

export const InteriorsTool: React.FC<ToolProps> = ({ active }) => {
  const { t } = useI18n();

  const rows = useMemo<InteriorRow[]>(
    () =>
      DATA.interiors.map((interior, index) => ({
        key: String(index),
        name: interior.name,
        search: interior.name.toLowerCase(),
        sub: t('info.world_position', {
          world: interior.world,
          x: interior.x.toFixed(1),
          y: interior.y.toFixed(1),
          z: interior.z.toFixed(1),
        }),
        world: interior.world,
        x: interior.x,
        y: interior.y,
        z: interior.z,
      })),
    [t]
  );

  return (
    <Browser
      id="interiors"
      active={active}
      rows={rows}
      actions={[
        {
          label: '@action.enter',
          variant: 'primary',
          run: (row) => row && nui('interior', { world: row.world, x: row.x, y: row.y, z: row.z }),
        },
      ]}
    />
  );
};

/// Vehicle

export const VehiclesTool: React.FC<ToolProps> = ({ active }) => {
  const rows = useMemo(() => namedRows(DATA.vehicles), []);

  return (
    <Browser
      id="vehicles"
      active={active}
      rows={rows}
      search="@search.vehicles"
      actions={[{ label: '@action.create_nearby', variant: 'primary', run: (row) => nui('vehicle', { id: row?.id }) }]}
    />
  );
};

interface UpgradeRow extends Row {
  id: number;
  installed: boolean;
}

export const UpgradesTool: React.FC<ToolProps> = ({ active }) => {
  const { t } = useI18n();
  const reply = usePoll<{ vehicle?: boolean; items?: Upgrade[] }>('upgrades', 400, {
    vehicle: true,
    items: [
      { id: 1010, slot: 'Nitro', installed: true },
      { id: 1025, slot: 'Wheels', installed: false },
    ],
  });

  const rows = useMemo<UpgradeRow[]>(
    () =>
      asArray<Upgrade>(reply?.items).map((upgrade) => ({
        key: String(upgrade.id),
        id: upgrade.id,
        installed: upgrade.installed,
        name: `${upgrade.slot} ${upgrade.id}`,
        group: upgrade.slot,
        search: `${upgrade.slot} ${upgrade.id}`.toLowerCase(),
        right: upgrade.installed ? t('upgrades.installed') : `#${upgrade.id}`,
        tone: upgrade.installed ? 'ok' : 'muted',
      })),
    [reply, t]
  );

  return (
    <Browser
      id="upgrades"
      active={active}
      rows={rows}
      empty={reply?.vehicle === false ? '@upgrades.enter_vehicle' : '@upgrades.not_supported'}
      actions={[
        { label: '@action.remove_all', free: true, run: () => nui('upgradesClear') },
        {
          label: (row) => (row?.installed ? '@action.remove_upgrade' : '@action.install_upgrade'),
          variant: 'primary',
          run: (row) => row && nui('upgrade', { id: row.id }),
        },
      ]}
    />
  );
};

export const PaintjobsTool: React.FC<ToolProps> = ({ active }) => {
  const rows = useMemo(() => namedRows(PAINTJOBS, false), []);

  return (
    <Browser
      id="paintjobs"
      active={active}
      rows={rows}
      actions={[{ label: '@common.apply', variant: 'primary', run: (row) => nui('paintjob', { id: row?.id }) }]}
    />
  );
};

/// Environment

export const TimeTool: React.FC<ToolProps> = ({ active }) => {
  const { state } = useFreeroam();
  const frozen = state?.frozen ?? false;

  const rows = useMemo(
    () =>
      presetRows(
        TIME_PRESETS,
        (preset) => `${pad(preset.value)}:00`,
        (preset) => ({ hour: pad(preset.value), minute: '00' })
      ),
    []
  );

  return (
    <Browser
      id="time"
      active={active}
      rows={rows}
      fields={[
        { id: 'hour', label: '@field.hour', initial: '12', width: 56, max: 2 },
        { id: 'minute', label: '@field.minute', initial: '00', width: 56, max: 2 },
      ]}
      actions={[
        {
          label: frozen ? '@action.unfreeze' : '@action.freeze',
          free: true,
          run: () => nui('toggle', { key: 'frozen', value: !frozen }),
        },
        {
          label: '@common.apply',
          variant: 'primary',
          free: true,
          run: (_, values) => nui('time', { hour: Number(values.hour), minute: Number(values.minute) }),
        },
      ]}
    />
  );
};

export const WeatherTool: React.FC<ToolProps> = ({ active }) => {
  const rows = useMemo(() => namedRows(DATA.weather), []);

  return (
    <Browser
      id="weather"
      active={active}
      rows={rows}
      actions={[{ label: '@common.apply', variant: 'primary', run: (row) => nui('weather', { id: row?.id }) }]}
    />
  );
};

export const GameSpeedTool: React.FC<ToolProps> = ({ active }) => {
  const rows = useMemo(
    () => presetRows(SPEED_PRESETS, (preset) => `${preset.value}x`, (preset) => ({ value: String(preset.value) })),
    []
  );

  return (
    <Browser
      id="gamespeed"
      active={active}
      rows={rows}
      fields={[{ id: 'value', label: '@field.exact', initial: '1', width: 72 }]}
      actions={[
        { label: '@common.apply', variant: 'primary', free: true, run: (_, values) => nui('speed', { value: Number(values.value) }) },
      ]}
    />
  );
};
