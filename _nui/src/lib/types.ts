export type Vec3 = { x: number; y: number; z: number };
export type Vec4 = Vec3 & { w: number };

export type PolyZone = { kind: 'poly'; points: Vec3[]; thickness: number };
export type BoxZone = { kind: 'box'; coords: Vec3; size: Vec3; rotation: number };
export type Zone = PolyZone | BoxZone;

export type Property = {
  id: number;
  name: string;
  price: number;
  shell: string;
  door: Vec4;
  zone?: Zone;
  garage?: Vec4;
  owned: boolean;
  ownerName?: string;
};

export type Shell = { key: string; label: string; category: string };

export type StarterLocation = { id: string; label: string; description: string };

export type Buyer = { serverId: number; name: string };

export type CreatorPayload = { properties: Property[]; shells: Shell[]; editId?: number };

export type OpenView = { view: 'creator'; payload: CreatorPayload } | { view: 'starter'; payload: { locations: StarterLocation[] } };

export type NuiMessage = { action: 'open'; data: OpenView; locales?: Record<string, string> } | { action: 'visible'; data: boolean } | { action: 'close' };

export type PlaceKind = 'door' | 'garage' | 'box' | 'poly';

export type PropertyDraft = {
  name: string;
  price: number;
  shell?: string;
  door?: Vec4;
  garage?: Vec4;
  zone?: Zone;
};

export type ActionResult = { ok: true } | { ok: false; error: string };
export type SaveResult = { ok: true; id: number } | { ok: false; error: string };

export type NuiCallbacks = {
  close: { args: Record<string, never>; result: boolean };
  'creator:refresh': { args: Record<string, never>; result: Property[] };
  'creator:save': { args: { id?: number; draft: PropertyDraft }; result: SaveResult };
  'creator:delete': { args: { id: number }; result: boolean };
  'creator:place': { args: { kind: PlaceKind; thickness: number; heading?: number }; result: Vec4 | Vec3[] | false };
  'creator:preview': { args: { shell: string }; result: boolean };
  'creator:buyers': { args: Record<string, never>; result: Buyer[] };
  'creator:offer': { args: { id: number; serverId: number }; result: ActionResult };
  'starter:choose': { args: { id: string }; result: boolean };
};

export function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function str(value: unknown): string | undefined {
  return typeof value === 'string' ? value : undefined;
}

function num(value: unknown): number | undefined {
  return typeof value === 'number' && Number.isFinite(value) ? value : undefined;
}

function list(value: unknown): unknown[] {
  if (Array.isArray(value)) return value;
  if (isRecord(value)) return Object.values(value);
  return [];
}

function compact<T>(values: (T | null)[]): T[] {
  return values.filter((value): value is T => value != null);
}

export function toVec3(value: unknown): Vec3 | null {
  if (!isRecord(value)) return null;
  const x = num(value.x);
  const y = num(value.y);
  const z = num(value.z);
  if (x == null || y == null || z == null) return null;
  return { x, y, z };
}

export function toVec4(value: unknown): Vec4 | null {
  const position = toVec3(value);
  const w = isRecord(value) ? num(value.w) : undefined;
  if (!position || w == null) return null;
  return { ...position, w };
}

export function toPoints(value: unknown): Vec3[] | null {
  const points = list(value).map(toVec3);
  const valid = compact(points);
  return valid.length >= 3 && valid.length === points.length ? valid : null;
}

function toZone(value: unknown): Zone | undefined {
  if (!isRecord(value)) return undefined;

  if (value.kind === 'box') {
    const coords = toVec3(value.coords);
    const size = toVec3(value.size);
    const rotation = num(value.rotation);
    if (!coords || !size || rotation == null) return undefined;
    return { kind: 'box', coords, size, rotation };
  }

  const thickness = num(value.thickness);
  const points = toPoints(value.points);
  if (value.kind !== 'poly' || thickness == null || !points) return undefined;
  return { kind: 'poly', points, thickness };
}

function toProperty(value: unknown): Property | null {
  if (!isRecord(value)) return null;
  const id = num(value.id);
  const name = str(value.name);
  const price = num(value.price);
  const shell = str(value.shell);
  const door = toVec4(value.door);
  if (id == null || name == null || price == null || shell == null || !door) return null;

  return {
    id,
    name,
    price,
    shell,
    door,
    zone: toZone(value.zone),
    garage: toVec4(value.garage) ?? undefined,
    owned: value.owned === true,
    ownerName: str(value.ownerName),
  };
}

export function toProperties(value: unknown): Property[] {
  return compact(list(value).map(toProperty));
}

function toShell(value: unknown): Shell | null {
  if (!isRecord(value)) return null;
  const key = str(value.key);
  const label = str(value.label);
  const category = str(value.category);
  if (!key || !label || !category) return null;
  return { key, label, category };
}

function toLocation(value: unknown): StarterLocation | null {
  if (!isRecord(value)) return null;
  const id = str(value.id);
  const label = str(value.label);
  if (!id || !label) return null;
  return { id, label, description: str(value.description) ?? '' };
}

export function toBuyers(value: unknown): Buyer[] {
  return compact(
    list(value).map((entry) => {
      if (!isRecord(entry)) return null;
      const serverId = num(entry.serverId);
      const name = str(entry.name);
      return serverId != null && name ? { serverId, name } : null;
    }),
  );
}

export function toSaveResult(value: unknown, fallback: string): SaveResult {
  if (isRecord(value) && value.ok === true && typeof value.id === 'number') return { ok: true, id: value.id };
  return { ok: false, error: (isRecord(value) && str(value.error)) || fallback };
}

export function toActionResult(value: unknown, fallback: string): ActionResult {
  if (isRecord(value) && value.ok === true) return { ok: true };
  return { ok: false, error: (isRecord(value) && str(value.error)) || fallback };
}

function toLocales(value: unknown): Record<string, string> | undefined {
  if (!isRecord(value)) return undefined;
  const entries = Object.entries(value).filter((entry): entry is [string, string] => typeof entry[1] === 'string');
  return Object.fromEntries(entries);
}

function toOpenView(value: unknown): OpenView | null {
  if (!isRecord(value) || !isRecord(value.payload)) return null;
  const payload = value.payload;

  if (value.view === 'creator') {
    return {
      view: 'creator',
      payload: {
        properties: toProperties(payload.properties),
        shells: compact(list(payload.shells).map(toShell)),
        editId: num(payload.editId),
      },
    };
  }

  if (value.view === 'starter') {
    return { view: 'starter', payload: { locations: compact(list(payload.locations).map(toLocation)) } };
  }

  return null;
}

export function toNuiMessage(value: unknown): NuiMessage | null {
  if (!isRecord(value)) return null;

  if (value.action === 'close') return { action: 'close' };
  if (value.action === 'visible') return { action: 'visible', data: value.data === true };

  if (value.action === 'open') {
    const view = toOpenView(value.data);
    return view ? { action: 'open', data: view, locales: toLocales(value.locales) } : null;
  }

  return null;
}
