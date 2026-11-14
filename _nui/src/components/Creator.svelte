<script lang="ts">
  import CaretLeftIcon from 'phosphor-svelte/lib/CaretLeftIcon';
  import XIcon from 'phosphor-svelte/lib/XIcon';
  import { untrack } from 'svelte';
  import { t } from '../lib/locale.svelte';
  import { nui } from '../lib/nui';
  import { toProperties, type CreatorPayload, type Property } from '../lib/types';
  import Button from './Button.svelte';
  import PropertyEditor from './PropertyEditor.svelte';
  import PropertyList from './PropertyList.svelte';

  type Screen = { kind: 'list' } | { kind: 'edit'; id?: number };

  interface Props {
    payload: CreatorPayload;
    onclose: () => void;
  }

  let { payload, onclose }: Props = $props();

  const initial = untrack(() => payload);

  let properties = $state<Property[]>(initial.properties);
  let screen = $state<Screen>(initial.editId != null ? { kind: 'edit', id: initial.editId } : { kind: 'list' });

  const editId = $derived(screen.kind === 'edit' ? screen.id : undefined);
  const editing = $derived(editId == null ? undefined : properties.find((property) => property.id === editId));
  const title = $derived(screen.kind === 'list' ? t('ui.creator.properties') : (editing?.name ?? t('ui.creator.new_property')));

  async function refresh(): Promise<void> {
    properties = toProperties(await nui('creator:refresh', {}));
  }

  async function saved(id: number): Promise<void> {
    await refresh();
    screen = { kind: 'edit', id };
  }

  async function deleted(): Promise<void> {
    await refresh();
    screen = { kind: 'list' };
  }

  function onkeydown(event: KeyboardEvent): void {
    if (event.key === 'Escape') onclose();
  }
</script>

<svelte:window {onkeydown} />

<aside class="fixed top-6 right-6 flex max-h-[calc(100vh-3rem)] w-[28rem] animate-enter flex-col rounded-lg border border-border bg-card shadow-lg">
  <header class="flex items-center gap-2 p-4">
    {#if screen.kind === 'edit'}
      <Button tone="ghost" size="icon" label={t('ui.creator.back_to_list')} onclick={() => (screen = { kind: 'list' })}>
        <CaretLeftIcon size={20} weight="fill" />
      </Button>
    {/if}
    <div class="flex min-w-0 flex-1 flex-col">
      <h1 class="truncate text-base font-semibold text-foreground">{title}</h1>
      <p class="text-xs text-muted-foreground">{t('ui.creator.subtitle')}</p>
    </div>
    <Button tone="ghost" size="icon" label={t('ui.common.close')} onclick={onclose}>
      <XIcon size={20} weight="fill" />
    </Button>
  </header>

  {#if screen.kind === 'list'}
    <PropertyList
      {properties}
      shells={payload.shells}
      onopen={(property) => (screen = { kind: 'edit', id: property.id })}
      oncreate={() => (screen = { kind: 'edit' })}
    />
  {:else}
    {#key editId ?? 'new'}
      <PropertyEditor property={editing} shells={payload.shells} onsaved={saved} ondeleted={deleted} onback={() => (screen = { kind: 'list' })} />
    {/key}
  {/if}
</aside>
