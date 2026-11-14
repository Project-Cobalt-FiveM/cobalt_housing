local config <const> = require 'config'
local Interior <const> = require 'client.interior'

local Cobalt <const> = exports.cobalt_core:GetCoreObject()

---@class PropertyMarkers
---@field target integer
---@field blip integer
---@field zone? CZone

local Properties <const> = {}

---@type table<integer, PublicProperty>
local properties <const> = {}
---@type table<integer, true>
local mine <const> = {}
---@type table<integer, PropertyMarkers>
local markers <const> = {}

---@type fun(propertyId?: integer)
local openCreator

---@param playerData table
---@return boolean
local function hasRealtorJob(playerData)
    return playerData.job?.name == config.job
end

local realtor = LocalPlayer.state.LoggedIn == true and hasRealtorJob(Cobalt.Functions.GetPlayerData())

---@return boolean
function Properties.isRealtor()
    return realtor
end

---@param handler fun(propertyId?: integer)
function Properties.onEdit(handler)
    openCreator = handler
end

---@param property PublicProperty
---@return integer
local function createBlip(property)
    local style <const> = mine[property.id] and config.blip.owned or config.blip.forSale
    local blip <const> = AddBlipForCoord(property.door.x, property.door.y, property.door.z)

    SetBlipSprite(blip, style.sprite)
    SetBlipColour(blip, style.colour)
    SetBlipScale(blip, style.scale)
    SetBlipAsShortRange(blip, true)
    SetBlipDisplay(blip, (property.owned and not mine[property.id]) and 0 or 4)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(mine[property.id] and property.name or locale('properties.blip_for_sale', property.name))
    EndTextCommandSetBlipName(blip)

    return blip
end

---@param property PublicProperty
local function announce(property)
    if property.owned then return end

    exports.cobalt_core:Notify({
        title = property.name,
        description = locale('properties.listing', lib.math.groupdigits(property.price)),
        type = 'inform',
    })
end

---@param property PublicProperty
---@return CZone?
local function createZone(property)
    local zone <const> = property.zone

    if not zone then return nil end

    if zone.kind == 'box' then
        return lib.zones.box({
            coords = zone.coords,
            size = zone.size,
            rotation = zone.rotation,
            onEnter = function() announce(properties[property.id]) end,
        })
    end

    return lib.zones.poly({
        points = zone.points,
        thickness = zone.thickness,
        onEnter = function() announce(properties[property.id]) end,
    })
end

---@param property PublicProperty
---@return integer
local function createTarget(property)
    local id <const> = property.id

    return exports.ox_target:addSphereZone({
        coords = property.door.xyz,
        radius = 1.2,
        options = {
            {
                name = 'cobalt_housing_enter',
                label = locale('properties.target_enter'),
                icon = 'fa-solid fa-door-open',
                distance = config.doorRange,
                canInteract = function() return mine[id] == true end,
                onSelect = function() Interior.enterProperty(id) end,
            },
            {
                name = 'cobalt_housing_listing',
                label = locale('properties.target_listing'),
                icon = 'fa-solid fa-sign-hanging',
                distance = config.doorRange,
                canInteract = function() return not properties[id].owned end,
                onSelect = function() announce(properties[id]) end,
            },
            {
                name = 'cobalt_housing_edit',
                label = locale('properties.target_edit'),
                icon = 'fa-solid fa-pen-ruler',
                distance = config.doorRange,
                canInteract = Properties.isRealtor,
                onSelect = function() openCreator(id) end,
            },
        },
    })
end

---@param id integer
local function removeMarkers(id)
    local marker <const> = markers[id]

    if not marker then return end

    exports.ox_target:removeZone(marker.target)
    RemoveBlip(marker.blip)

    if marker.zone then marker.zone:remove() end

    markers[id] = nil
end

---@param property PublicProperty
local function upsert(property)
    removeMarkers(property.id)
    properties[property.id] = property
    markers[property.id] = {
        target = createTarget(property),
        blip = createBlip(property),
        zone = createZone(property),
    }
end

---@param rebuildAll? boolean upsert every property, not only those whose ownership changed
local function refreshOwned(rebuildAll)
    local before <const> = table.clone(mine)

    table.wipe(mine)

    for _, id in ipairs(lib.callback.await('cobalt_housing:owned', false) or {}) do
        mine[id] = true
    end

    for id, property in pairs(properties) do
        if rebuildAll or before[id] ~= mine[id] then upsert(property) end
    end
end

local function load()
    for id in pairs(markers) do
        removeMarkers(id)
    end

    table.wipe(properties)

    for _, property in ipairs(lib.callback.await('cobalt_housing:properties', false) or {}) do
        properties[property.id] = property
    end

    refreshOwned(true)
end

RegisterNetEvent('cobalt_housing:client:propertyChanged', function(property)
    if not LocalPlayer.state.LoggedIn then return end

    upsert(property)
end)

RegisterNetEvent('cobalt_housing:client:propertyRemoved', function(id)
    removeMarkers(id)
    properties[id] = nil
    mine[id] = nil
end)

RegisterNetEvent('cobalt_housing:client:ownedChanged', function() refreshOwned() end)

RegisterNetEvent('cobalt_housing:client:offer', function(offer)
    local answer <const> = exports.cobalt_core:AlertDialog({
        header = locale('properties.offer.header'),
        content = locale('properties.offer.content', offer.realtor, offer.name, lib.math.groupdigits(offer.price)),
        cancel = true,
        labels = { confirm = locale('properties.offer.confirm'), cancel = locale('properties.offer.decline') },
    })

    TriggerServerEvent('cobalt_housing:server:answerOffer', answer == 'confirm')
end)

local function unload()
    for id in pairs(markers) do
        removeMarkers(id)
    end

    table.wipe(properties)
    table.wipe(mine)
    realtor = false
end

RegisterNetEvent('cobalt_core:Player:SetPlayerData', function(playerData)
    realtor = hasRealtorJob(playerData)
end)

AddStateBagChangeHandler('LoggedIn', ('player:%s'):format(cache.serverId), function(_, _, loggedIn)
    if loggedIn then
        CreateThread(load)
        return
    end

    unload()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    for _, marker in pairs(markers) do
        RemoveBlip(marker.blip)
    end
end)

if LocalPlayer.state.LoggedIn then CreateThread(load) end

return Properties
