local db <const> = require 'server.db'

---@class PublicProperty : PropertyDraft
---@field id integer
---@field owned boolean

local Properties <const> = {}

---@type table<integer, Property>
local byId <const> = {}
local ready <const> = promise.new()

---@param property Property
---@return PublicProperty
local function public(property)
    return {
        id = property.id,
        name = property.name,
        price = property.price,
        shell = property.shell,
        door = property.door,
        zone = property.zone,
        garage = property.garage,
        owned = property.owner ~= nil,
    }
end

---@param property Property
local function broadcast(property)
    TriggerClientEvent('cobalt_housing:client:propertyChanged', -1, public(property))
end

function Properties.load()
    for _, property in ipairs(db.all()) do
        byId[property.id] = property
    end

    ready:resolve(true)
end

---@param id integer
---@return Property?
function Properties.get(id)
    return byId[id]
end

---@param citizenid string
---@param id integer
---@return boolean
function Properties.hasAccess(citizenid, id)
    local owner <const> = byId[id]?.owner

    return owner ~= nil and owner == citizenid
end

---@return PublicProperty[]
function Properties.list()
    Citizen.Await(ready)

    local list <const> = {}

    for _, property in pairs(byId) do
        list[#list + 1] = public(property)
    end

    table.sort(list, function(a, b) return a.id < b.id end)

    return list
end

---@param citizenid string
---@return Property[]
function Properties.ownedBy(citizenid)
    local list <const> = {}

    for _, property in pairs(byId) do
        if property.owner == citizenid then list[#list + 1] = property end
    end

    table.sort(list, function(a, b) return a.id < b.id end)

    return list
end

---@param query string
---@return Property[]
function Properties.find(query)
    local needle <const> = query:lower()
    local list <const> = {}

    for _, property in pairs(byId) do
        if property.name:lower():find(needle, 1, true) then list[#list + 1] = property end
    end

    table.sort(list, function(a, b) return a.id < b.id end)

    return list
end

---@param draft PropertyDraft
---@param createdBy string
---@return Property?
function Properties.create(draft, createdBy)
    local id <const>, stashId <const> = db.insert(draft, createdBy)

    if not id then return nil end

    local property <const> = table.clone(draft) --[[@as Property]]
    property.id = id
    property.stashId = stashId
    byId[id] = property

    broadcast(property)

    return property
end

---@param id integer
---@param draft PropertyDraft
---@return Property?
function Properties.update(id, draft)
    local property <const> = byId[id]

    if not property or not db.update(id, draft) then return nil end

    property.name = draft.name
    property.price = draft.price
    property.shell = draft.shell
    property.door = draft.door
    property.zone = draft.zone
    property.garage = draft.garage

    broadcast(property)

    return property
end

---@param id integer
---@return boolean
function Properties.removeUnowned(id)
    if not db.deleteUnowned(id) then return false end

    byId[id] = nil
    TriggerClientEvent('cobalt_housing:client:propertyRemoved', -1, id)

    return true
end

---@param id integer
---@param citizenid string
---@param charge fun(): boolean
---@return boolean
function Properties.purchase(id, citizenid, charge)
    local property <const> = byId[id]

    if not property or property.owner then return false end
    if not db.purchase(id, citizenid, charge) then return false end

    property.owner = citizenid
    property.stash = nil
    property.wardrobe = nil

    broadcast(property)

    return true
end

---@param id integer
---@param citizenid string
---@param kind FurnitureKind
---@param offset vector3
---@return boolean
function Properties.setFurniture(id, citizenid, kind, offset)
    local property <const> = byId[id]

    if not property or property.owner ~= citizenid then return false end
    if not db.setFurniture(id, citizenid, kind, offset) then return false end

    property[kind] = offset

    return true
end

AddEventHandler('cobalt_core:characterDeleted', function(citizenid)
    for _, property in ipairs(Properties.ownedBy(citizenid)) do
        property.owner = nil
        property.stash = nil
        property.wardrobe = nil

        broadcast(property)
    end
end)

return Properties
