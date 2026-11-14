<script lang="ts">
  import type CarIcon from 'phosphor-svelte/lib/CarIcon';
  import { formatCoords } from '../lib/format';
  import { t } from '../lib/locale.svelte';
  import type { Vec3 } from '../lib/types';
  import Button from './Button.svelte';

  interface Props {
    icon: typeof CarIcon;
    value?: Vec3;
    empty: string;
    action: string;
    onplace: () => void;
    onclear?: () => void;
  }

  let { icon: Icon, value, empty, action, onplace, onclear }: Props = $props();
</script>

<div class="flex items-center justify-between gap-3 rounded-md border border-border bg-card px-3 py-2">
  <span class="flex min-w-0 items-center gap-2 text-sm text-foreground">
    <span class="text-muted-foreground"><Icon size={16} weight="fill" /></span>
    <span class="truncate tabular-nums {value ? '' : 'text-muted-foreground'}">{value ? formatCoords(value) : empty}</span>
  </span>
  <span class="flex shrink-0 gap-1">
    {#if onclear}
      <Button size="sm" tone="ghost" onclick={onclear}>{t('ui.common.remove')}</Button>
    {/if}
    <Button size="sm" onclick={onplace}>{action}</Button>
  </span>
</div>
