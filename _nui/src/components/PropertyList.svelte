<script lang="ts">
  import HouseIcon from 'phosphor-svelte/lib/HouseIcon';
  import MagnifyingGlassIcon from 'phosphor-svelte/lib/MagnifyingGlassIcon';
  import PlusIcon from 'phosphor-svelte/lib/PlusIcon';
  import { formatMoney } from '../lib/format';
  import { t } from '../lib/locale.svelte';
  import type { Property, Shell } from '../lib/types';
  import { focusRing, motion } from '../lib/ui';
  import Button from './Button.svelte';
  import Input from './Input.svelte';

  interface Props {
    properties: Property[];
    shells: Shell[];
    onopen: (property: Property) => void;
    oncreate: () => void;
  }

  let { properties, shells, onopen, oncreate }: Props = $props();

  let query = $state('');

  const shellLabels = $derived(new Map(shells.map((shell) => [shell.key, shell.label])));

  const visible = $derived.by(() => {
    const needle = query.trim().toLowerCase();
    if (!needle) return properties;
    return properties.filter((property) =>
      [property.name, property.ownerName ?? '', shellLabels.get(property.shell) ?? ''].join(' ').toLowerCase().includes(needle),
    );
  });

  const forSale = $derived(properties.filter((property) => !property.owned).length);
</script>

<div class="flex min-h-0 flex-1 flex-col">
  <div class="flex flex-col gap-3 px-4 pb-4">
    <p class="text-xs text-muted-foreground tabular-nums">
      {t(properties.length === 1 ? 'ui.list.count_one' : 'ui.list.count_many', properties.length, forSale)}
    </p>
    <div class="flex gap-2">
      <div class="flex-1">
        <Input bind:value={query} placeholder={t('ui.list.search')} label={t('ui.list.search_label')}>
          <MagnifyingGlassIcon size={16} weight="fill" />
        </Input>
      </div>
      <Button tone="primary" onclick={oncreate}>
        <PlusIcon size={16} weight="fill" />
        {t('ui.list.new_property')}
      </Button>
    </div>
  </div>

  <div class="flex min-h-0 flex-1 flex-col gap-1 overflow-y-auto border-t border-border p-2">
    {#if visible.length === 0}
      <div class="flex animate-fade flex-col items-center gap-2 px-6 py-12 text-center">
        <span class="text-muted-foreground"><HouseIcon size={20} weight="fill" /></span>
        <p class="text-sm text-foreground">{properties.length === 0 ? t('ui.list.empty_title') : t('ui.list.no_match_title')}</p>
        <p class="text-xs text-muted-foreground">
          {properties.length === 0 ? t('ui.list.empty_hint') : t('ui.list.no_match_hint')}
        </p>
      </div>
    {/if}

    {#each visible as property (property.id)}
      <button
        type="button"
        onclick={() => onopen(property)}
        class="flex items-center gap-3 rounded-md px-3 py-2.5 text-left hover:bg-muted {focusRing} {motion}"
      >
        <span class="flex min-w-0 flex-1 flex-col">
          <span class="truncate text-sm font-medium text-foreground">{property.name}</span>
          <span class="truncate text-xs text-muted-foreground">
            {property.owned ? t('ui.list.owned_by', property.ownerName ?? t('ui.list.a_resident')) : (shellLabels.get(property.shell) ?? property.shell)}
          </span>
        </span>
        {#if property.owned}
          <span class="rounded-sm bg-secondary px-2 py-0.5 text-xs font-medium text-foreground">{t('ui.list.sold')}</span>
        {:else}
          <span class="text-sm font-medium text-foreground tabular-nums">{formatMoney(property.price)}</span>
        {/if}
      </button>
    {/each}
  </div>
</div>
