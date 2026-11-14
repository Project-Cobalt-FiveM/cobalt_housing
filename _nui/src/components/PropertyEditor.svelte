<script lang="ts">
  import CarIcon from 'phosphor-svelte/lib/CarIcon';
  import CheckIcon from 'phosphor-svelte/lib/CheckIcon';
  import DoorIcon from 'phosphor-svelte/lib/DoorIcon';
  import EyeIcon from 'phosphor-svelte/lib/EyeIcon';
  import MapPinIcon from 'phosphor-svelte/lib/MapPinIcon';
  import PolygonIcon from 'phosphor-svelte/lib/PolygonIcon';
  import TrashIcon from 'phosphor-svelte/lib/TrashIcon';
  import UserIcon from 'phosphor-svelte/lib/UserIcon';
  import { untrack } from 'svelte';
  import { formatMoney } from '../lib/format';
  import { t } from '../lib/locale.svelte';
  import { nui } from '../lib/nui';
  import {
    toActionResult,
    toBuyers,
    toPoints,
    toSaveResult,
    toVec4,
    type Buyer,
    type PlaceKind,
    type Property,
    type Shell,
    type Vec3,
    type Vec4,
    type Zone,
  } from '../lib/types';
  import { focusRing, motion } from '../lib/ui';
  import Button from './Button.svelte';
  import Field from './Field.svelte';
  import Input from './Input.svelte';
  import Kbd from './Kbd.svelte';
  import PlacementRow from './PlacementRow.svelte';
  import Section from './Section.svelte';

  type ZoneKind = 'none' | 'poly' | 'box';

  type Draft = {
    name: string;
    price: string;
    shell?: string;
    door?: Vec4;
    garage?: Vec4;
    zoneKind: ZoneKind;
    points: Vec3[];
    thickness: string;
    boxCentre?: Vec4;
    boxWidth: string;
    boxLength: string;
    boxHeight: string;
  };

  type Status = { tone: 'error' | 'success'; text: string };

  interface Props {
    property?: Property;
    shells: Shell[];
    onsaved: (id: number) => void;
    ondeleted: () => void;
    onback: () => void;
  }

  let { property, shells, onsaved, ondeleted, onback }: Props = $props();

  const zoneKinds: readonly { value: ZoneKind; label: string }[] = [
    { value: 'none', label: 'ui.editor.zone_none' },
    { value: 'poly', label: 'ui.editor.zone_poly' },
    { value: 'box', label: 'ui.editor.zone_box' },
  ];

  const boxFields = [
    { label: 'ui.editor.width', key: 'boxWidth' },
    { label: 'ui.editor.length', key: 'boxLength' },
    { label: 'ui.editor.height', key: 'boxHeight' },
  ] as const;

  function draftFrom(source?: Property): Draft {
    const zone = source?.zone;

    return {
      name: source?.name ?? '',
      price: source ? String(source.price) : '',
      shell: source?.shell,
      door: source?.door,
      garage: source?.garage,
      zoneKind: zone?.kind ?? 'none',
      points: zone?.kind === 'poly' ? zone.points : [],
      thickness: zone?.kind === 'poly' ? String(zone.thickness) : '6',
      boxCentre: zone?.kind === 'box' ? { ...zone.coords, w: zone.rotation } : undefined,
      boxWidth: zone?.kind === 'box' ? String(zone.size.x) : '20',
      boxLength: zone?.kind === 'box' ? String(zone.size.y) : '20',
      boxHeight: zone?.kind === 'box' ? String(zone.size.z) : '8',
    };
  }

  function zoneFrom(source: Draft): Zone | undefined {
    if (source.zoneKind === 'poly' && source.points.length >= 3) {
      return { kind: 'poly', points: source.points, thickness: Number(source.thickness) };
    }

    if (source.zoneKind === 'box' && source.boxCentre) {
      const { x, y, z, w } = source.boxCentre;
      return {
        kind: 'box',
        coords: { x, y, z },
        size: { x: Number(source.boxWidth), y: Number(source.boxLength), z: Number(source.boxHeight) },
        rotation: w,
      };
    }

    return undefined;
  }

  const digits = (value: string): string => value.replace(/\D/g, '').slice(0, 9);
  const decimal = (value: string): string => value.replace(/[^\d.]/g, '');

  let draft = $state<Draft>(untrack(() => draftFrom(property)));
  let status = $state<Status | null>(null);
  let busy = $state(false);
  let confirmDelete = $state(false);
  let shellQuery = $state('');
  let buyers = $state<Buyer[] | null>(null);
  let buyer = $state<number>();

  const groups = $derived.by(() => {
    const needle = shellQuery.trim().toLowerCase();
    const map = new Map<string, Shell[]>();
    for (const shell of shells) {
      if (needle && !`${shell.label} ${shell.category}`.toLowerCase().includes(needle)) continue;
      map.set(shell.category, [...(map.get(shell.category) ?? []), shell]);
    }
    return [...map.entries()];
  });

  const selectedShell = $derived(shells.find((shell) => shell.key === draft.shell));
  const canSave = $derived(draft.name.trim() !== '' && draft.price !== '' && draft.shell != null && draft.door != null);

  function headingFor(kind: PlaceKind): number | undefined {
    if (kind === 'door') return draft.door?.w;
    if (kind === 'garage') return draft.garage?.w;
    if (kind === 'box') return draft.boxCentre?.w;
    return undefined;
  }

  async function place(kind: PlaceKind): Promise<void> {
    const result = await nui('creator:place', { kind, thickness: Number(draft.thickness), heading: headingFor(kind) });

    if (kind === 'poly') {
      const points = toPoints(result);
      if (points) draft.points = points;
      return;
    }

    const point = toVec4(result);
    if (!point) return;
    if (kind === 'door') draft.door = point;
    if (kind === 'garage') draft.garage = point;
    if (kind === 'box') draft.boxCentre = point;
  }

  async function save(): Promise<void> {
    busy = true;
    status = null;

    const result = toSaveResult(
      await nui('creator:save', {
        id: property?.id,
        draft: {
          name: draft.name,
          price: Number(draft.price),
          shell: draft.shell,
          door: draft.door,
          garage: draft.garage,
          zone: zoneFrom(draft),
        },
      }),
      t('ui.editor.save_failed'),
    );

    busy = false;

    if (!result.ok) {
      status = { tone: 'error', text: result.error };
      return;
    }

    status = { tone: 'success', text: t('ui.editor.saved') };
    onsaved(result.id);
  }

  async function remove(): Promise<void> {
    if (!property) return;

    if ((await nui('creator:delete', { id: property.id })) === true) {
      ondeleted();
      return;
    }

    confirmDelete = false;
    status = { tone: 'error', text: t('ui.editor.delete_failed') };
  }

  async function findBuyers(): Promise<void> {
    const found = toBuyers(await nui('creator:buyers', {}));
    buyers = found;
    buyer = found[0]?.serverId;
  }

  async function sendOffer(): Promise<void> {
    if (!property || buyer == null) return;

    const result = toActionResult(await nui('creator:offer', { id: property.id, serverId: buyer }), t('ui.editor.offer_failed'));

    status = result.ok ? { tone: 'success', text: t('ui.editor.offer_sent') } : { tone: 'error', text: result.error };
  }

  function preview(): void {
    if (draft.shell) void nui('creator:preview', { shell: draft.shell });
  }

  function stepZone(event: KeyboardEvent & { currentTarget: HTMLElement }): void {
    const offset = event.key === 'ArrowRight' ? 1 : event.key === 'ArrowLeft' ? -1 : 0;
    if (offset === 0) return;
    event.preventDefault();
    const index = zoneKinds.findIndex((option) => option.value === draft.zoneKind);
    const next = zoneKinds[(index + offset + zoneKinds.length) % zoneKinds.length];
    if (!next) return;
    draft.zoneKind = next.value;
    event.currentTarget.querySelector<HTMLElement>(`[data-value="${next.value}"]`)?.focus();
  }
</script>

<div class="flex min-h-0 flex-1 animate-fade flex-col">
  <div class="min-h-0 flex-1 overflow-y-auto">
    <div class="flex flex-col gap-4 px-4 pb-4">
      <Field label={t('ui.editor.name')}>
        <Input bind:value={draft.name} maxlength={64} placeholder={t('ui.editor.name_placeholder')} autofocus={!property} />
      </Field>
      <Field label={t('ui.editor.price')} hint={draft.price ? formatMoney(Number(draft.price)) : t('ui.editor.price_hint')}>
        <Input bind:value={draft.price} prefix="$" inputmode="numeric" numeric placeholder="250000" oninput={digits} />
      </Field>
    </div>

    <Section title={t('ui.editor.door_title')} description={t('ui.editor.door_description')}>
      <PlacementRow
        icon={DoorIcon}
        value={draft.door}
        empty={t('ui.editor.not_placed')}
        action={draft.door ? t('ui.editor.move_door') : t('ui.editor.place_door')}
        onplace={() => place('door')}
      />
    </Section>

    <Section title={t('ui.editor.interior_title')} description={t('ui.editor.interior_description')}>
      <div class="flex gap-2">
        <div class="flex-1">
          <Input bind:value={shellQuery} placeholder={t('ui.editor.search_shells')} label={t('ui.editor.search_shells')} />
        </div>
        <Button disabled={!draft.shell} onclick={preview}>
          <EyeIcon size={16} weight="fill" />
          {t('ui.editor.preview')}
        </Button>
      </div>
      <div role="listbox" aria-label={t('ui.editor.shells')} class="flex max-h-64 flex-col gap-3 overflow-y-auto rounded-md border border-border p-1">
        {#if groups.length === 0}
          <p class="px-2 py-3 text-xs text-muted-foreground">{t('ui.editor.no_shell_match')}</p>
        {/if}
        {#each groups as [category, items] (category)}
          <div class="flex flex-col gap-0.5">
            <p class="px-2 pt-1 text-xs text-muted-foreground">{category}</p>
            {#each items as shell (shell.key)}
              {@const active = shell.key === draft.shell}
              <button
                type="button"
                role="option"
                aria-selected={active}
                onclick={() => (draft.shell = shell.key)}
                class="flex h-8 shrink-0 items-center justify-between rounded-md border px-2 text-left text-sm {active
                  ? 'border-primary bg-primary text-primary-foreground'
                  : 'border-transparent text-foreground hover:bg-muted'} {focusRing} {motion}"
              >
                <span class="truncate">{shell.label}</span>
                {#if active}
                  <CheckIcon size={16} weight="fill" />
                {/if}
              </button>
            {/each}
          </div>
        {/each}
      </div>
      {#if selectedShell}
        <p class="text-xs text-muted-foreground">{t('ui.editor.selected_shell', selectedShell.label)}</p>
      {/if}
    </Section>

    <Section title={t('ui.editor.zone_title')} description={t('ui.editor.zone_description')}>
      <div role="radiogroup" aria-label={t('ui.editor.zone_shape')} tabindex="-1" class="grid grid-cols-3 gap-1 rounded-md bg-secondary p-1 outline-none" onkeydown={stepZone}>
        {#each zoneKinds as option (option.value)}
          {@const selected = draft.zoneKind === option.value}
          <button
            type="button"
            role="radio"
            aria-checked={selected}
            data-value={option.value}
            tabindex={selected ? 0 : -1}
            onclick={() => (draft.zoneKind = option.value)}
            class="h-7 rounded-sm text-xs font-medium {selected
              ? 'bg-primary text-primary-foreground'
              : 'text-muted-foreground hover:text-foreground'} {focusRing} {motion}"
          >
            {t(option.label)}
          </button>
        {/each}
      </div>

      {#if draft.zoneKind === 'poly'}
        <Field label={t('ui.editor.height')} hint={t('ui.editor.height_hint')}>
          <Input bind:value={draft.thickness} inputmode="decimal" numeric oninput={decimal} />
        </Field>
        <div class="flex items-center justify-between gap-3 rounded-md border border-border bg-card px-3 py-2">
          <span class="flex items-center gap-2 text-sm text-foreground">
            <span class="text-muted-foreground"><PolygonIcon size={16} weight="fill" /></span>
            <span class="tabular-nums">{draft.points.length ? t('ui.editor.corners', draft.points.length) : t('ui.editor.not_drawn')}</span>
          </span>
          <Button size="sm" onclick={() => place('poly')}>{draft.points.length ? t('ui.editor.redraw') : t('ui.editor.draw_corners')}</Button>
        </div>
        <p class="flex flex-wrap items-center gap-1.5 text-xs text-muted-foreground">
          <Kbd>{t('ui.keys.e')}</Kbd> {t('ui.editor.poly_add')} <Kbd>{t('ui.keys.x')}</Kbd> {t('ui.editor.poly_undo')} <Kbd>{t('ui.keys.enter')}</Kbd> {t('ui.editor.poly_finish')}
        </p>
      {:else if draft.zoneKind === 'box'}
        <PlacementRow
          icon={MapPinIcon}
          value={draft.boxCentre}
          empty={t('ui.editor.center_not_placed')}
          action={draft.boxCentre ? t('ui.editor.move_center') : t('ui.editor.place_center')}
          onplace={() => place('box')}
        />
        <div class="grid grid-cols-3 gap-2">
          {#each boxFields as field (field.key)}
            <Field label={t(field.label)}>
              <Input bind:value={draft[field.key]} inputmode="decimal" numeric oninput={decimal} />
            </Field>
          {/each}
        </div>
        <p class="text-xs text-muted-foreground">{t('ui.editor.box_hint')}</p>
      {/if}
    </Section>

    <Section title={t('ui.editor.garage_title')} description={t('ui.editor.garage_description')}>
      <PlacementRow
        icon={CarIcon}
        value={draft.garage}
        empty={t('ui.editor.no_garage')}
        action={draft.garage ? t('ui.editor.move_garage') : t('ui.editor.place_garage')}
        onplace={() => place('garage')}
        onclear={draft.garage ? () => (draft.garage = undefined) : undefined}
      />
    </Section>

    {#if property && !property.owned}
      <Section title={t('ui.editor.sell_title')} description={t('ui.editor.sell_description')}>
        {#if buyers === null}
          <Button onclick={findBuyers}>
            <UserIcon size={16} weight="fill" />
            {t('ui.editor.find_buyers')}
          </Button>
        {:else if buyers.length === 0}
          <div class="flex items-center justify-between gap-3">
            <p class="text-xs text-muted-foreground">{t('ui.editor.no_buyers')}</p>
            <Button size="sm" onclick={findBuyers}>{t('ui.editor.look_again')}</Button>
          </div>
        {:else}
          <div class="flex flex-col gap-2">
            <div role="radiogroup" aria-label={t('ui.editor.buyer')} class="flex flex-col gap-1">
              {#each buyers as entry (entry.serverId)}
                {@const selected = buyer === entry.serverId}
                <button
                  type="button"
                  role="radio"
                  aria-checked={selected}
                  onclick={() => (buyer = entry.serverId)}
                  class="flex h-9 items-center justify-between rounded-md border px-3 text-sm {selected
                    ? 'border-primary bg-primary text-primary-foreground'
                    : 'border-border bg-card text-foreground hover:bg-muted'} {focusRing} {motion}"
                >
                  {entry.name}
                  <span class="text-xs tabular-nums">{t('ui.common.id', entry.serverId)}</span>
                </button>
              {/each}
            </div>
            <Button onclick={sendOffer} disabled={buyer == null}>{t('ui.editor.offer_for', formatMoney(property.price))}</Button>
          </div>
        {/if}
      </Section>
    {/if}

    {#if property?.owned}
      <Section title={t('ui.editor.owner_title')} description={t('ui.editor.owner_description')}>
        <p class="text-sm text-foreground">{property.ownerName ?? t('ui.editor.a_resident')}</p>
      </Section>
    {/if}
  </div>

  <div class="flex flex-col gap-3 border-t border-border p-4">
    {#if status}
      <p class="animate-fade text-xs {status.tone === 'error' ? 'text-destructive' : 'text-muted-foreground'}" role="status">{status.text}</p>
    {/if}

    {#if confirmDelete && property}
      <div class="flex animate-fade flex-col gap-3">
        <p class="text-sm text-foreground">{t('ui.editor.delete_confirm', property.name)}</p>
        <div class="flex justify-end gap-2">
          <Button tone="ghost" onclick={() => (confirmDelete = false)}>{t('ui.common.cancel')}</Button>
          <Button tone="destructive" onclick={remove}>{t('ui.editor.delete_property')}</Button>
        </div>
      </div>
    {:else}
      <div class="flex items-center gap-2">
        {#if property && !property.owned}
          <Button tone="destructive" size="icon" label={t('ui.editor.delete_property')} onclick={() => (confirmDelete = true)}>
            <TrashIcon size={16} weight="fill" />
          </Button>
        {/if}
        <Button tone="ghost" push onclick={onback}>{t('ui.common.back')}</Button>
        <Button tone="primary" onclick={save} disabled={!canSave || busy}>
          {busy ? t('ui.editor.saving') : property ? t('ui.editor.save_changes') : t('ui.editor.create_property')}
        </Button>
      </div>
    {/if}
  </div>
</div>
