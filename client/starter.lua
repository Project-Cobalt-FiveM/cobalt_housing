local config <const> = require 'config'
local Interior <const> = require 'client.interior'
local Nui <const> = require 'client.nui'

local Cobalt <const> = exports.cobalt_core:GetCoreObject()
local starter <const> = require '@cobalt_core.config.shared'.starterApartment

---@type integer[]
local targets <const> = {}
---@type integer?
local blip
---@type string?
local blipLocation
---@type string?
local myLocation = LocalPlayer.state.LoggedIn and Cobalt.Functions.GetPlayerData().metadata?.starterApartment or nil

---@param id? string
---@return table?
local function findLocation(id)
    if not starter.enabled or not id then return nil end

    for _, location in ipairs(starter.locations) do
        if location.id == id then return location end
    end
end

---@param id? string
local function syncBlip(id)
    if id == blipLocation then return end

    if blip then RemoveBlip(blip) end

    blip = nil
    blipLocation = id

    local location <const> = findLocation(id)

    if not location then return end

    local style <const> = config.blip.starter
    blip = AddBlipForCoord(location.door.x, location.door.y, location.door.z)

    SetBlipSprite(blip, style.sprite)
    SetBlipColour(blip, style.colour)
    SetBlipScale(blip, style.scale)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(location.label)
    EndTextCommandSetBlipName(blip)
end

local function createDoors()
    if not starter.enabled then return end

    for _, location in ipairs(starter.locations) do
        local id <const> = location.id

        targets[#targets + 1] = exports.ox_target:addSphereZone({
            coords = location.door.xyz,
            radius = 1.2,
            options = {
                {
                    name = 'cobalt_housing_starter',
                    label = locale('starter.target'),
                    icon = 'fa-solid fa-bed',
                    distance = config.doorRange,
                    canInteract = function() return myLocation == id end,
                    onSelect = function() Interior.enterStarter() end,
                },
            },
        })
    end
end

local function skipPicker()
    DoScreenFadeIn(250)
    TriggerEvent('qb-clothes:client:CreateFirstCharacter')
end

AddEventHandler('cobalt_housing:client:chooseStarterApartment', function()
    if not lib.callback.await('cobalt_housing:openStarterPicker', false) then
        return skipPicker()
    end

    local locations <const> = {}

    for i, location in ipairs(starter.locations) do
        locations[i] = { id = location.id, label = location.label, description = location.description }
    end

    Nui.open('starter', { locations = locations })
end)

RegisterNUICallback('starter:choose', function(data, cb)
    local view <const>, reason <const>, closed <const> = lib.callback.await('cobalt_housing:chooseStarter', false, data.id)

    cb(view ~= nil)

    if closed then
        Nui.close()
        exports.cobalt_core:Notify({ title = locale('notify.title'), description = reason, type = 'error' })
        return skipPicker()
    end

    if not view then return end

    Nui.close()
    Interior.enter(view)
    TriggerEvent('qb-clothes:client:CreateFirstCharacter')
end)

RegisterNetEvent('cobalt_core:Player:SetPlayerData', function(playerData)
    myLocation = playerData.metadata?.starterApartment
    syncBlip(myLocation)
end)

AddStateBagChangeHandler('LoggedIn', ('player:%s'):format(cache.serverId), function(_, _, loggedIn)
    if loggedIn then return end

    myLocation = nil
    syncBlip(nil)
end)

CreateThread(createDoors)

syncBlip(myLocation)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    syncBlip(nil)

    for _, target in ipairs(targets) do
        exports.ox_target:removeZone(target)
    end
end)
