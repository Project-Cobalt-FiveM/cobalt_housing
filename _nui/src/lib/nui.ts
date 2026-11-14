import { toNuiMessage, type NuiCallbacks, type NuiMessage } from './types';

declare global {
  interface Window {
    GetParentResourceName?: () => string;
  }
}

export type CallbackName = keyof NuiCallbacks;
export type CallbackArgs<K extends CallbackName> = NuiCallbacks[K]['args'];
export type CallbackResult<K extends CallbackName> = NuiCallbacks[K]['result'];

export type MockHandlers = { [K in CallbackName]: (args: CallbackArgs<K>) => CallbackResult<K> };

let mockHandlers: MockHandlers | null = null;

export const inGame = 'GetParentResourceName' in window;

const resourceName = window.GetParentResourceName?.() ?? 'cobalt_housing';

export function installMock(handlers: MockHandlers): void {
  mockHandlers = handlers;
}

async function mockReply<K extends CallbackName>(handlers: MockHandlers, name: K, args: CallbackArgs<K>): Promise<CallbackResult<K>> {
  await new Promise((resolve) => setTimeout(resolve, 120));
  return handlers[name](args);
}

export async function nui<K extends CallbackName>(name: K, args: CallbackArgs<K>): Promise<unknown> {
  if (mockHandlers) return mockReply(mockHandlers, name, args);
  try {
    const response = await fetch(`https://${resourceName}/${name}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(args),
    });
    const body: unknown = await response.json();
    return body;
  } catch {
    return null;
  }
}

export function onNuiMessage(handler: (message: NuiMessage) => void): () => void {
  const listener = (event: MessageEvent<unknown>) => {
    const message = toNuiMessage(event.data);
    if (message) handler(message);
  };
  window.addEventListener('message', listener);
  return () => window.removeEventListener('message', listener);
}
