<script lang="ts">
  import Creator from './components/Creator.svelte';
  import StarterPicker from './components/StarterPicker.svelte';
  import { setLocales } from './lib/locale.svelte';
  import { nui, onNuiMessage } from './lib/nui';
  import type { OpenView } from './lib/types';

  let open = $state<OpenView | null>(null);
  let visible = $state(true);

  $effect(() =>
    onNuiMessage((message) => {
      if (message.action === 'open') {
        setLocales(message.locales);
        open = message.data;
        visible = true;
        return;
      }
      if (message.action === 'visible') {
        visible = message.data;
        return;
      }
      open = null;
    }),
  );

  function close(): void {
    open = null;
    void nui('close', {});
  }
</script>

{#if open}
  <div class="font-sans text-foreground {visible ? '' : 'invisible'}">
    {#if open.view === 'creator'}
      {#key open.payload}
        <Creator payload={open.payload} onclose={close} />
      {/key}
    {:else}
      <StarterPicker locations={open.payload.locations} />
    {/if}
  </div>
{/if}
