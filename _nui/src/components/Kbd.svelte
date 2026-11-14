<script lang="ts">
  import type { Snippet } from 'svelte';

  let { children }: { children: Snippet } = $props();
</script>

<kbd class="rounded-sm border border-border bg-muted px-1.5 font-sans text-xs text-muted-foreground">{@render children()}</kbd>
