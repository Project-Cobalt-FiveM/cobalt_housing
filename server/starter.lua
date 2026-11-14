local config <const> = require 'config'
local Occupancy <const> = require 'server.occupancy'
local Players <const> = require 'server.players'
local starter <const> = require '@cobalt_core.config.shared'.starterApartment

---@class StarterLocation
---@field id string
---@field label string
---@field description string
---@field door vector4

---@class StarterPick
---@field closesAt integer
---@field pickerOpened boolean

---@type table<integer, StarterPick>
local picks <const> = {}

---@param source integer
---@return StarterPick?
local function openPick(source)
    local pick <const> = picks[source]

    if not pick or pick.closesAt < GetGameTimer() then return end

    return pick
end

---@return integer
local function pickDeadline()
    return GetGameTimer() + config.starterPickSeconds * 1000
end

---@param id unknown
---@return StarterLocation?
local function findLocation(id)
    if not starter.enabled or type(id) ~= 'string' then return nil end

    for _, location in ipairs(starter.locations) do
        if location.id == id then return location end
    end
end

---@param source integer
---@param location StarterLocation
---@param citizenid string
---@return InteriorView?, string?
local function enter(source, location, citizenid)
    return Occupancy.enter(source, {
        kind = 'starter',
        shell = starter.shell,
        door = location.door,
        stashId = 'starter',
        stashOwner = citizenid,
    }, config.buckets.starter + source)
end

---@param source integer
---@return boolean
local function openPicker(source)
    local pick <const> = openPick(source)

    if not pick or pick.pickerOpened then return false end

    pick.pickerOpened = true
    pick.closesAt = pickDeadline()

    return true
end

---@param source integer
---@param id unknown
---@return InteriorView? view
---@return string? reason
---@return boolean? closed true when no later pick can succeed either
local function choose(source, id)
    local player <const> = Players.get(source)

    if not player then return nil, locale('starter.unavailable') end
    if player.PlayerData.metadata.starterApartment then return nil, locale('starter.already_have_room'), true end

    if not openPick(source) then
        picks[source] = nil
        return nil, locale('starter.picker_closed'), true
    end

    local location <const> = findLocation(id)

    if not location then return nil, locale('starter.unavailable') end

    picks[source] = nil
    player.Functions.SetMetaData('starterApartment', location.id)

    return enter(source, location, player.PlayerData.citizenid)
end

---@param source integer
---@return InteriorView?, string?
local function enterOwn(source)
    local player <const> = Players.get(source)
    local location <const> = player and findLocation(player.PlayerData.metadata.starterApartment)

    if not player or not location then return nil, locale('starter.no_room') end
    if not Players.near(source, location.door, config.doorCheckRange) then
        return nil, locale('starter.stand_at_door')
    end

    return enter(source, location, player.PlayerData.citizenid)
end

lib.callback.register('cobalt_housing:openStarterPicker', openPicker)
lib.callback.register('cobalt_housing:chooseStarter', choose)
lib.callback.register('cobalt_housing:enterStarter', enterOwn)

AddEventHandler('cobalt_core:Server:PlayerLoaded', function(player)
    if player.PlayerData.metadata.starterApartment then return end

    picks[player.PlayerData.source] = { closesAt = pickDeadline(), pickerOpened = false }
end)

AddEventHandler('cobalt_core:Server:OnPlayerUnload', function(source)
    picks[source] = nil
end)

AddEventHandler('playerDropped', function()
    picks[source] = nil
end)
