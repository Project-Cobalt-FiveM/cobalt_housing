<script lang="ts">
  import BedIcon from 'phosphor-svelte/lib/BedIcon';
  import { untrack } from 'svelte';
  import { t } from '../lib/locale.svelte';
  import { nui } from '../lib/nui';
  import type { StarterLocation } from '../lib/types';
  import { focusRing, motion } from '../lib/ui';
  import Button from './Button.svelte';

  let { locations }: { locations: StarterLocation[] } = $props();

  let selected = $state<string | undefined>(untrack(() => locations[0]?.id));
  let busy = $state(false);
  let error = $state<string>();

  async function moveIn(): Promise<void> {
    if (!selected || busy) return;
    busy = true;
    error = undefined;

    const ok = await nui('starter:choose', { id: selected });

    if (ok !== true) {
      busy = false;
      error = t('ui.starter.unavailable');
    }
  }

  function onkeydown(event: KeyboardEvent & { currentTarget: HTMLElement }): void {
    if (event.key !== 'ArrowDown' && event.key !== 'ArrowUp') return;
    event.preventDefault();
    const index = locations.findIndex((location) => location.id === selected);
    const step = event.key === 'ArrowDown' ? 1 : -1;
    const next = locations[(index + step + locations.length) % locations.length];
    if (!next) return;
    selected = next.id;
    event.currentTarget.querySelector<HTMLElement>(`[data-id="${next.id}"]`)?.focus();
  }
</script>

<div class="flex h-screen items-center justify-center p-6">
  <div class="flex w-full max-w-md animate-pop flex-col gap-6 rounded-lg border border-border bg-popover p-6 shadow-lg">
    <div class="flex flex-col gap-1">
      <h1 class="text-2xl font-semibold tracking-tight text-foreground">{t('ui.starter.title')}</h1>
      <p class="text-sm text-muted-foreground">{t('ui.starter.description')}</p>
    </div>

    <div role="radiogroup" aria-label={t('ui.starter.rooms')} tabindex="-1" class="flex flex-col gap-2 outline-none" {onkeydown}>
      {#each locations as location (location.id)}
        {@const active = location.id === selected}
        <button
          type="button"
          role="radio"
          aria-checked={active}
          data-id={location.id}
          tabindex={active ? 0 : -1}
          onclick={() => (selected = location.id)}
          ondblclick={moveIn}
          class="flex items-center gap-3 rounded-md border px-3 py-2.5 text-left {active
            ? 'border-primary bg-primary text-primary-foreground'
            : 'border-border bg-card text-foreground hover:bg-muted'} {focusRing} {motion}"
        >
          <span class={active ? 'text-primary-foreground' : 'text-muted-foreground'}><BedIcon size={20} weight="fill" /></span>
          <span class="flex flex-col">
            <span class="text-sm font-medium">{location.label}</span>
            <span class="text-xs {active ? 'text-primary-foreground' : 'text-muted-foreground'}">{location.description}</span>
          </span>
        </button>
      {/each}
    </div>

    {#if error}
      <p class="animate-fade text-xs text-destructive" role="alert">{error}</p>
    {/if}

    <div class="flex justify-end">
      <Button tone="primary" onclick={moveIn} disabled={!selected || busy}>{busy ? t('ui.starter.moving_in') : t('ui.starter.move_in')}</Button>
    </div>
  </div>
</div>
