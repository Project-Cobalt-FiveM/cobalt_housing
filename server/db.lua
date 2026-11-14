---@class PropertyDraft
---@field name string
---@field price integer
---@field shell string
---@field door vector4
---@field zone? PropertyZone
---@field garage? vector4

---@class Property : PropertyDraft
---@field id integer
---@field stashId string cobalt_inventory stash name, built from the property's id and creation time
---@field owner? string
---@field stash? vector3
---@field wardrobe? vector3

---@alias FurnitureKind 'stash' | 'wardrobe'

local db <const> = {}

local SELECT_ALL <const> = [[
    SELECT id, name, price, owner, shell, door, zone, garage, stash, wardrobe,
        DATE_FORMAT(created_at, '%Y%m%d%H%i%s') AS created
    FROM properties
    ORDER BY id
    LIMIT 5000
]]

local SELECT_OWNER_NAMES <const> = [[
    SELECT pr.id,
        CONCAT_WS(' ', JSON_UNQUOTE(JSON_EXTRACT(pl.charinfo, '$.firstname')), JSON_UNQUOTE(JSON_EXTRACT(pl.charinfo, '$.lastname'))) AS owner_name
    FROM properties pr
    JOIN players pl ON pl.citizenid = pr.owner
    ORDER BY pr.id
    LIMIT 5000
]]

local INSERT <const> = [[
    INSERT INTO properties (name, price, shell, door, zone, garage, created_by)
    VALUES (?, ?, ?, ?, ?, ?, ?)
]]

local SELECT_CREATED <const> = "SELECT DATE_FORMAT(created_at, '%Y%m%d%H%i%s') FROM properties WHERE id = ?"

---@param id integer
---@param created string the row's created_at as YYYYMMDDHHMMSS, which no database time zone setting changes
---@return string stash name such as `property_12_20261110153045`, unique even if property ids restart
local function stashName(id, created)
    return ('property_%d_%s'):format(id, created)
end

local UPDATE <const> = 'UPDATE properties SET name = ?, price = ?, shell = ?, door = ?, zone = ?, garage = ? WHERE id = ? AND owner IS NULL'
local DELETE_UNOWNED <const> = 'DELETE FROM properties WHERE id = ? AND owner IS NULL'
local CLAIM <const> = [[
    UPDATE properties
    SET owner = ?, stash = NULL, wardrobe = NULL, purchased_at = CURRENT_TIMESTAMP
    WHERE id = ? AND owner IS NULL
]]

local SET_FURNITURE <const> = {
    stash = 'UPDATE properties SET stash = ? WHERE id = ? AND owner = ?',
    wardrobe = 'UPDATE properties SET wardrobe = ? WHERE id = ? AND owner = ?',
}

---@param value? vector2 | vector3 | vector4
---@return table?
local function plain(value)
    if not value then return nil end

    local kind <const> = type(value)

    if kind == 'vector4' then return { x = value.x, y = value.y, z = value.z, w = value.w } end
    if kind == 'vector3' then return { x = value.x, y = value.y, z = value.z } end

    return { x = value.x, y = value.y }
end

---@param zone? PropertyZone
---@return string?
local function encodeZone(zone)
    if not zone then return nil end

    if zone.kind == 'box' then
        return json.encode({
            kind = 'box',
            coords = plain(zone.coords),
            size = plain(zone.size),
            rotation = zone.rotation,
        })
    end

    local points <const> = {}

    for i, point in ipairs(zone.points) do
        points[i] = plain(point)
    end

    return json.encode({ kind = 'poly', points = points, thickness = zone.thickness })
end

---@param value? table
---@return vector3?
local function toVec3(value)
    if not value then return nil end

    return vector3(value.x, value.y, value.z)
end

---@param value? table
---@return vector4?
local function toVec4(value)
    if not value then return nil end

    return vector4(value.x, value.y, value.z, value.w or 0.0)
end

---@param raw? string
---@return PropertyZone?
local function decodeZone(raw)
    local zone <const> = raw and json.decode(raw)

    if not zone then return nil end

    if zone.kind == 'box' then
        return {
            kind = 'box',
            coords = toVec3(zone.coords),
            size = toVec3(zone.size),
            rotation = zone.rotation or 0.0,
        }
    end

    local points <const> = {}

    for i, point in ipairs(zone.points) do
        points[i] = toVec3(point)
    end

    return { kind = 'poly', points = points, thickness = zone.thickness or 4.0 }
end

---@param raw? string
---@return table?
local function decode(raw)
    return raw and json.decode(raw) or nil
end

---@param value? vector3 | vector4
---@return string?
local function encode(value)
    local data <const> = plain(value)

    return data and json.encode(data)
end

---@return Property[]
function db.all()
    local rows <const> = MySQL.query.await(SELECT_ALL)
    local list <const> = {}

    for i, row in ipairs(rows) do
        list[i] = {
            id = row.id,
            name = row.name,
            price = row.price,
            owner = row.owner,
            shell = row.shell,
            door = toVec4(decode(row.door)),
            zone = decodeZone(row.zone),
            garage = toVec4(decode(row.garage)),
            stash = toVec3(decode(row.stash)),
            wardrobe = toVec3(decode(row.wardrobe)),
            stashId = stashName(row.id, row.created),
        }
    end

    return list
end

---@return table<integer, string>
function db.ownerNames()
    local names <const> = {}

    for _, row in ipairs(MySQL.query.await(SELECT_OWNER_NAMES)) do
        names[row.id] = row.owner_name
    end

    return names
end

---@param draft PropertyDraft
---@param createdBy string
---@return integer? id
---@return string? stashId
function db.insert(draft, createdBy)
    local id <const> = MySQL.insert.await(INSERT, {
        draft.name,
        draft.price,
        draft.shell,
        encode(draft.door),
        encodeZone(draft.zone),
        encode(draft.garage),
        createdBy,
    })

    if not id then return nil end

    local created <const> = MySQL.scalar.await(SELECT_CREATED, { id })

    if not created then return nil end

    return id, stashName(id, created)
end

---@param id integer
---@param draft PropertyDraft
---@return boolean
function db.update(id, draft)
    return MySQL.update.await(UPDATE, {
        draft.name,
        draft.price,
        draft.shell,
        encode(draft.door),
        encodeZone(draft.zone),
        encode(draft.garage),
        id,
    }) == 1
end

---@param id integer
---@return boolean
function db.deleteUnowned(id)
    return MySQL.update.await(DELETE_UNOWNED, { id }) == 1
end

---@param id integer
---@param citizenid string
---@param charge fun(): boolean
---@return boolean
function db.purchase(id, citizenid, charge)
    return MySQL.startTransaction(function(query)
        if query(CLAIM, { citizenid, id }).affectedRows ~= 1 then return false end

        return charge()
    end) == true
end

---@param id integer
---@param citizenid string
---@param kind FurnitureKind
---@param offset vector3
---@return boolean
function db.setFurniture(id, citizenid, kind, offset)
    return MySQL.update.await(SET_FURNITURE[kind], { encode(offset), id, citizenid }) == 1
end

return db
