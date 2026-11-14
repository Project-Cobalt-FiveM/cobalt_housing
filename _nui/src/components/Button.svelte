<script lang="ts" module>
  export type ButtonTone = 'primary' | 'secondary' | 'ghost' | 'destructive';
  export type ButtonSize = 'md' | 'sm' | 'icon';
</script>

<script lang="ts">
  import type { Snippet } from 'svelte';
  import { focusRing, motion } from '../lib/ui';

  interface Props {
    tone?: ButtonTone;
    size?: ButtonSize;
    disabled?: boolean;
    label?: string;
    push?: boolean;
    onclick?: () => void;
    children: Snippet;
  }

  let { tone = 'secondary', size = 'md', disabled = false, label, push = false, onclick, children }: Props = $props();

  const tones: Record<ButtonTone, string> = {
    primary: 'border-cobalt bg-primary text-primary-foreground hover:border-cobalt-hover hover:bg-cobalt-hover',
    secondary: 'border-input bg-secondary text-foreground hover:bg-input',
    ghost: 'border-transparent text-muted-foreground hover:bg-muted hover:text-foreground',
    destructive: 'border-destructive-solid bg-destructive-solid text-foreground hover:border-destructive-hover hover:bg-destructive-hover',
  };

  const sizes: Record<ButtonSize, string> = {
    md: 'h-9 px-4 text-sm',
    sm: 'h-8 px-3 text-xs',
    icon: 'size-9',
  };

  const look = $derived(disabled ? 'border-input bg-secondary text-muted-foreground cursor-not-allowed' : tones[tone]);
</script>

<button
  type="button"
  {disabled}
  {onclick}
  aria-label={label}
  class="inline-flex shrink-0 items-center justify-center gap-2 rounded-md border font-medium tabular-nums {sizes[size]} {look} {push
    ? 'mr-auto'
    : ''} {focusRing} {motion}"
>
  {@render children()}
</button>
