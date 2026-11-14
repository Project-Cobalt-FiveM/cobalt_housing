<script lang="ts">
  import type { Snippet } from 'svelte';

  interface Props {
    label: string;
    hint?: string;
    children: Snippet;
  }

  let { label, hint, children }: Props = $props();
</script>

<label class="flex flex-col gap-1.5">
  <span class="text-sm font-medium text-foreground">{label}</span>
  {@render children()}
  {#if hint}
    <span class="text-xs text-muted-foreground tabular-nums">{hint}</span>
  {/if}
</label>
