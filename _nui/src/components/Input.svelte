<script lang="ts">
  import type { Snippet } from 'svelte';
  import { focusOnMount, focusRing, motion } from '../lib/ui';

  interface Props {
    value: string;
    placeholder?: string;
    label?: string;
    prefix?: string;
    maxlength?: number;
    inputmode?: 'numeric' | 'decimal' | 'text';
    numeric?: boolean;
    autofocus?: boolean;
    oninput?: (value: string) => string;
    children?: Snippet;
  }

  let { value = $bindable(), placeholder, label, prefix, maxlength, inputmode = 'text', numeric = false, autofocus = false, oninput, children }: Props = $props();

  function sanitize(event: Event & { currentTarget: HTMLInputElement }): void {
    if (!oninput) return;
    const next = oninput(event.currentTarget.value);
    event.currentTarget.value = next;
    value = next;
  }
</script>

<div class="relative">
  {#if prefix}
    <span class="pointer-events-none absolute inset-y-0 left-3 flex items-center text-sm text-muted-foreground">{prefix}</span>
  {/if}
  {#if children}
    <span class="pointer-events-none absolute inset-y-0 left-3 flex items-center text-muted-foreground">{@render children()}</span>
  {/if}
  <input
    bind:value
    {placeholder}
    {maxlength}
    {inputmode}
    aria-label={label}
    autocomplete="off"
    spellcheck="false"
    oninput={sanitize}
    {@attach autofocus && focusOnMount}
    class="h-9 w-full rounded-md border border-input bg-transparent px-3 text-sm text-foreground caret-cobalt placeholder:text-muted-foreground {prefix
      ? 'pl-7'
      : ''} {children ? 'pl-9' : ''} {numeric ? 'tabular-nums' : ''} {focusRing} {motion}"
  />
</div>
