import { installMock, type MockHandlers } from './nui';
import type { Property, Shell, StarterLocation, Vec3 } from './types';

const params = new URLSearchParams(window.location.search);
const view = params.get('view') === 'starter' ? 'starter' : 'creator';
const editParam = Number(params.get('edit'));
const editId = Number.isInteger(editParam) && editParam > 0 ? editParam : undefined;

const shells: Shell[] = [
  { key: 'apartment_low', label: 'Low-end studio', category: 'Apartment' },
  { key: 'apartment_mid', label: 'Mid-range apartment', category: 'Apartment' },
  { key: 'eclipse_modern', label: 'Eclipse Towers, modern', category: 'Penthouse' },
  { key: 'eclipse_seductive', label: 'Eclipse Towers, seductive', category: 'Penthouse' },
  { key: 'house_hills', label: 'Hillside house', category: 'House' },
  { key: 'house_franklin', label: "Franklin's house", category: 'House' },
  { key: 'motel_room', label: 'Motel room', category: 'Starter' },
];

let nextId = 4;

let properties: Property[] = [
  {
    id: 1,
    name: '2044 North Conker Avenue',
    price: 1250000,
    shell: 'house_hills',
    door: { x: 346.2, y: 440.6, z: 147.7, w: 120 },
    garage: { x: 354.1, y: 437.9, z: 145.6, w: 300 },
    zone: { kind: 'box', coords: { x: 349.0, y: 439.0, z: 146.0 }, size: { x: 30, y: 25, z: 10 }, rotation: 30 },
    owned: false,
  },
  {
    id: 2,
    name: 'Eclipse Towers, apartment 31',
    price: 685000,
    shell: 'eclipse_modern',
    door: { x: -773.1, y: 312.4, z: 85.7, w: 180 },
    owned: true,
    ownerName: 'Maya Chen',
  },
  {
    id: 3,
    name: '0112 South Rockford Drive',
    price: 240000,
    shell: 'apartment_mid',
    door: { x: -810.4, y: -980.6, z: 14.2, w: 90 },
    owned: false,
  },
];

const locations: StarterLocation[] = [
  { id: 'pinkcage', label: 'Pink Cage Motel', description: 'Alta Street, close to Legion Square' },
  { id: 'bayview', label: 'Bayview Lodge', description: 'Paleto Bay, by the highway' },
  { id: 'dream', label: 'Dream View Motel', description: 'Sandy Shores, Route 68' },
];

const corner = (x: number, y: number): Vec3 => ({ x, y, z: 30 });

const handlers: MockHandlers = {
  close: () => true,
  'creator:refresh': () => properties,
  'creator:save': ({ id, draft }) => {
    if (!draft.shell || !draft.door) return { ok: false, error: 'Place the door' };
    const existing = properties.find((property) => property.id === id);
    const saved: Property = {
      ...draft,
      id: existing?.id ?? nextId++,
      shell: draft.shell,
      door: draft.door,
      owned: existing?.owned ?? false,
      ownerName: existing?.ownerName,
    };
    properties = existing ? properties.map((property) => (property.id === saved.id ? saved : property)) : [...properties, saved];
    return { ok: true, id: saved.id };
  },
  'creator:delete': ({ id }) => {
    properties = properties.filter((property) => property.id !== id || property.owned);
    return true;
  },
  'creator:place': ({ kind, heading }) =>
    kind === 'poly' ? [corner(-10, 4), corner(12, 6), corner(14, -9), corner(-8, -11)] : { x: 214.6, y: -811.2, z: 30.7, w: heading ?? 90 },
  'creator:preview': () => true,
  'creator:buyers': () => [
    { serverId: 12, name: 'Maya Chen' },
    { serverId: 27, name: 'Luis Ortega' },
  ],
  'creator:offer': () => ({ ok: true }),
  'starter:choose': () => true,
};

installMock(handlers);
document.body.style.background = '#3B4A3A';

setTimeout(() => {
  const payload = view === 'starter' ? { locations } : { properties, shells, editId };
  window.postMessage({ action: 'open', data: { view, payload } });
}, 50);
