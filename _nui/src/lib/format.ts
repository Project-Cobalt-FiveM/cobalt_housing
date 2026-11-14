import type { Vec3 } from './types';

const money = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 });

export function formatMoney(value: number): string {
  return money.format(value);
}

export function formatCoords(value: Vec3): string {
  return `${value.x.toFixed(1)}, ${value.y.toFixed(1)}, ${value.z.toFixed(1)}`;
}
