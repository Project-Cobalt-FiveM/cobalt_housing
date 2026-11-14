import type { Attachment } from 'svelte/attachments';

export const focusRing =
  'outline-none focus-visible:ring-2 focus-visible:ring-cobalt focus-visible:ring-offset-2 focus-visible:ring-offset-background';

export const motion = 'transition-colors duration-150 ease-cobalt';

export const focusOnMount: Attachment<HTMLElement> = (node) => {
  node.focus();
};
