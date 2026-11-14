<script lang="ts">
  import type { Snippet } from 'svelte';

  interface Props {
    title: string;
    description?: string;
    children: Snippet;
  }

  let { title, description, children }: Props = $props();
</script>

<section class="flex flex-col gap-3 border-t border-border px-4 py-4">
  <div class="flex flex-col gap-0.5">
    <h3 class="text-base font-semibold text-foreground">{title}</h3>
    {#if description}
      <p class="text-xs text-muted-foreground">{description}</p>
    {/if}
  </div>
  {@render children()}
</section>
