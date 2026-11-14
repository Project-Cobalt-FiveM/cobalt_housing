local config <const> = require 'config'
local shells <const> = require 'shared.shells'
local Properties <const> = require 'server.properties'
local Players <const> = require 'server.players'

---@alias OccupancyKind 'property' | 'starter' | 'preview'

---@class Occupancy
---@field kind OccupancyKind
---@field shell string
---@field door vector4
---@field propertyId? integer
---@field stashId? string
---@field stashOwner? string citizenid whose personal copy of the stash opens; nil for a property's shared stash

---@class InteriorView
---@field kind OccupancyKind
---@field shell string
---@field stash? vector3
---@field wardrobe? vector3
---@field canFurnish boolean

local Occupancy <const> = {}

---@type table<integer, Occupancy>
local occupants <const> = {}

---@param occupancy Occupancy
---@return vector3?, vector3?
local function furniture(occupancy)
    local entry <const> = shells[occupancy.shell].entry.xyz

    if occupancy.kind == 'property' then
        local property <const> = Properties.get(occupancy.propertyId --[[@as integer]])

        if not property then return nil, nil end

        return property.stash and entry + property.stash, property.wardrobe and entry + property.wardrobe
    end

    if occupancy.kind == 'starter' then
        local shell <const> = shells[occupancy.shell]

        return shell.stash and entry + shell.stash, shell.wardrobe and entry + shell.wardrobe
    end

    return nil, nil
end

---@param occupancy Occupancy
---@return InteriorView
local function view(occupancy)
    local stash <const>, wardrobe <const> = furniture(occupancy)

    return {
        kind = occupancy.kind,
        shell = occupancy.shell,
        stash = stash,
        wardrobe = wardrobe,
        canFurnish = occupancy.kind == 'property',
    }
end

---@param source integer
---@return Occupancy?
function Occupancy.get(source)
    return occupants[source]
end

---@param source integer
---@param occupancy Occupancy
---@param bucket integer
---@return InteriorView?, string?
function Occupancy.enter(source, occupancy, bucket)
    local player <const> = Players.get(source)

    if not player then return nil, locale('occupancy.not_loaded') end
    if not shells[occupancy.shell] then return nil, locale('occupancy.no_interior') end

    occupants[source] = occupancy
    Players.setBucket(source, bucket)

    local door <const> = occupancy.door
    player.Functions.SetMetaData('inside', {
        shell = occupancy.shell,
        door = { x = door.x, y = door.y, z = door.z, w = door.w },
    })

    return view(occupancy)
end

---@param source integer
---@return vector4?
function Occupancy.leave(source)
    local occupancy <const> = occupants[source]

    if not occupancy then return nil end

    occupants[source] = nil
    Players.setBucket(source, 0)

    local player <const> = Players.get(source)

    if player then player.Functions.SetMetaData('inside', nil) end

    return occupancy.door
end

---@param source integer
---@param propertyId integer
---@return InteriorView?, string?
local function enterProperty(source, propertyId)
    local player <const> = Players.get(source)
    local property <const> = type(propertyId) == 'number' and Properties.get(propertyId)

    if not player or not property then return nil, locale('occupancy.no_property') end
    if property.owner ~= player.PlayerData.citizenid then return nil, locale('occupancy.not_owner') end
    if not Players.near(source, property.door, config.doorCheckRange) then return nil, locale('occupancy.stand_at_door') end

    return Occupancy.enter(source, {
        kind = 'property',
        shell = property.shell,
        door = property.door,
        propertyId = property.id,
        stashId = property.stashId,
    }, config.buckets.property + property.id)
end

---@param source integer
---@param kind FurnitureKind
---@return InteriorView?
local function placeFurniture(source, kind)
    local occupancy <const> = occupants[source]
    local player <const> = Players.get(source)

    if not occupancy or occupancy.kind ~= 'property' or not player then return nil end
    if kind ~= 'stash' and kind ~= 'wardrobe' then return nil end

    local entry <const> = shells[occupancy.shell].entry.xyz
    local offset <const> = Players.coords(source) - entry

    if #offset > config.maxPlacementDistance then return nil end

    local placed <const> = Properties.setFurniture(
        occupancy.propertyId --[[@as integer]],
        player.PlayerData.citizenid,
        kind,
        offset
    )

    return placed and view(occupancy) or nil
end

---@param source integer
---@return boolean
local function openStash(source)
    local occupancy <const> = occupants[source]
    local stash <const> = occupancy and furniture(occupancy)

    if not occupancy or not stash or not occupancy.stashId then return false end
    if not Players.near(source, stash, config.furnitureRange) then return false end

    if occupancy.propertyId then
        local citizenid <const> = Players.get(source)?.PlayerData.citizenid

        if not citizenid or not Properties.hasAccess(citizenid, occupancy.propertyId) then return false end
    end

    exports.cobalt_inventory:CreateStash(occupancy.stashId, {
        slots = config.stash.slots,
        maxWeight = config.stash.maxWeight,
        label = locale('occupancy.stash_label'),
        personal = occupancy.stashOwner ~= nil,
    })

    return exports.cobalt_inventory:OpenStash(source, occupancy.stashId, occupancy.stashOwner) == true
end

lib.callback.register('cobalt_housing:enter', enterProperty)
lib.callback.register('cobalt_housing:leave', Occupancy.leave)
lib.callback.register('cobalt_housing:placeFurniture', placeFurniture)
lib.callback.register('cobalt_housing:openStash', openStash)

AddEventHandler('cobalt_core:Server:PlayerLoaded', function(player)
    local source <const> = player.PlayerData.source
    local inside <const> = player.PlayerData.metadata.inside

    if not inside then return end

    player.Functions.SetMetaData('inside', nil)
    TriggerClientEvent('cobalt_housing:client:leftInside', source, inside.shell, inside.door)
end)

AddEventHandler('cobalt_core:Server:OnPlayerUnload', function(source)
    if not occupants[source] then return end

    occupants[source] = nil
    Players.setBucket(source, 0)
end)

AddEventHandler('playerDropped', function()
    occupants[source] = nil
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    for source in pairs(occupants) do
        local door <const> = Occupancy.leave(source)
        local ped <const> = GetPlayerPed(source)

        if door and ped ~= 0 then
            SetEntityCoords(ped, door.x, door.y, door.z, false, false, false, false)
            SetEntityHeading(ped, door.w)
        end
    end
end)

return Occupancy
