local config <const> = require 'config'
local shells <const> = require 'shared.shells'
local Properties <const> = require 'server.properties'
local Occupancy <const> = require 'server.occupancy'
local Players <const> = require 'server.players'
local Parse <const> = require 'server.parse'
local db <const> = require 'server.db'

---@class RealtorProperty : PublicProperty
---@field ownerName? string

---@class SaleOffer
---@field propertyId integer
---@field realtor integer
---@field realtorCitizenid string
---@field price integer
---@field expires integer

---@type table<integer, SaleOffer>
local offers <const> = {}

---@param source integer
---@return RealtorProperty[]?
local function list(source)
    if not Players.realtor(source) then return nil end

    local names <const> = db.ownerNames()
    local rows <const> = Properties.list() --[[@as RealtorProperty[] ]]

    for _, row in ipairs(rows) do
        row.ownerName = names[row.id]
    end

    return rows
end

---@param source integer
---@param id? integer
---@param input unknown
---@return { ok: boolean, error?: string, id?: integer }
local function save(source, id, input)
    local realtor <const> = Players.realtor(source)

    if not realtor then return { ok = false, error = locale('realtor.realtors_only') } end

    local draft <const>, err <const> = Parse.draft(input, Players.coords(source))

    if not draft then return { ok = false, error = err } end

    local property

    if id == nil then
        property = Properties.create(draft, realtor.PlayerData.citizenid)
    elseif math.type(id) == 'integer' then
        if Properties.get(id)?.owner then
            return { ok = false, error = locale('realtor.sold_locked') }
        end

        property = Properties.update(id, draft)
    end

    if not property then return { ok = false, error = locale('realtor.save_failed') } end

    local message <const> = ('Saved property %d (%s)'):format(property.id, property.name)

    exports.cobalt_core:LogPlayer(source, 'housing:listing_saved', message, {
        propertyId = property.id,
        price = property.price,
    })

    return { ok = true, id = property.id }
end

---@param source integer
---@param id unknown
---@return boolean
local function remove(source, id)
    local realtor <const> = Players.realtor(source)

    if not realtor or math.type(id) ~= 'integer' then return false end
    if not Properties.removeUnowned(id --[[@as integer]]) then return false end

    exports.cobalt_core:LogPlayer(source, 'housing:listing_deleted', ('Deleted property %d'):format(id), { propertyId = id })

    return true
end

---@param source integer
---@param shell unknown
---@return InteriorView?
local function preview(source, shell)
    if not Players.realtor(source) or type(shell) ~= 'string' or not shells[shell] then return nil end

    local coords <const> = Players.coords(source)

    return Occupancy.enter(source, {
        kind = 'preview',
        shell = shell,
        door = vector4(coords.x, coords.y, coords.z, GetEntityHeading(GetPlayerPed(source))),
    }, config.buckets.preview + source)
end

---@param source integer
---@return { serverId: integer, name: string }[]
local function buyers(source)
    if not Players.realtor(source) then return {} end

    local origin <const> = Players.coords(source)
    local nearby <const> = {}

    for _, playerId in ipairs(lib.getNearbyPlayers(origin, config.buyerRange)) do
        local id <const> = playerId.id
        local player <const> = id ~= source and Players.get(id)

        if player then nearby[#nearby + 1] = { serverId = id, name = Players.name(player) } end
    end

    return nearby
end

---@param source integer
---@param propertyId unknown
---@param buyerId unknown
---@return { ok: boolean, error?: string }
local function offer(source, propertyId, buyerId)
    local realtor <const> = Players.realtor(source)
    local property <const> = math.type(propertyId) == 'integer' and Properties.get(propertyId --[[@as integer]])
    local buyer <const> = math.type(buyerId) == 'integer' and buyerId ~= source and Players.get(buyerId --[[@as integer]])

    if not realtor then return { ok = false, error = locale('realtor.realtors_only') } end
    if not property or property.owner then return { ok = false, error = locale('realtor.not_for_sale') } end
    if not buyer then return { ok = false, error = locale('realtor.pick_buyer') } end
    if not Players.near(buyerId --[[@as integer]], Players.coords(source), config.buyerRange) then
        return { ok = false, error = locale('realtor.buyer_too_far') }
    end

    local pending <const> = offers[buyerId]

    if pending and pending.expires > os.time() then return { ok = false, error = locale('realtor.offer_open') } end

    offers[buyerId] = {
        propertyId = property.id,
        realtor = source,
        realtorCitizenid = realtor.PlayerData.citizenid,
        price = property.price,
        expires = os.time() + config.offerSeconds,
    }

    TriggerClientEvent('cobalt_housing:client:offer', buyerId, {
        name = property.name,
        price = property.price,
        realtor = Players.name(realtor),
        seconds = config.offerSeconds,
    })

    return { ok = true }
end

---@param buyer table
---@param sale SaleOffer
---@param reason string
---@return boolean
local function charge(buyer, sale, reason)
    if sale.price == 0 then return true end

    local society <const> = 'society_' .. config.job

    if not exports.cobalt_banking:GetAccount(society) then
        return buyer.Functions.RemoveMoney('bank', sale.price, reason)
    end

    return exports.cobalt_banking:Transfer(buyer.PlayerData.citizenid, society, sale.price, {
        note = reason,
        initiator = sale.realtorCitizenid,
        bill = true,
    }) == true
end

---@param buyerId integer
---@param sale SaleOffer
---@return boolean, string?
local function completeSale(buyerId, sale)
    local buyer <const> = Players.get(buyerId)
    local property <const> = Properties.get(sale.propertyId)

    if not buyer or not property or property.owner then return false, locale('realtor.no_longer_for_sale') end
    if property.price ~= sale.price then return false, locale('realtor.price_changed') end

    local citizenid <const> = buyer.PlayerData.citizenid
    local reason <const> = locale('realtor.purchase_note', property.name)

    local bought <const> = Properties.purchase(property.id, citizenid, function()
        return charge(buyer, sale, reason)
    end)

    if not bought then
        if property.owner then return false, locale('realtor.no_longer_for_sale') end

        local balance <const> = buyer.Functions.GetMoney('bank')

        return false, locale('realtor.not_enough_money', balance, sale.price)
    end

    local message <const> = ('Bought property %d (%s)'):format(property.id, property.name)

    exports.cobalt_core:LogPlayer(buyerId, 'housing:property_bought', message, {
        propertyId = property.id,
        price = sale.price,
        realtor = sale.realtorCitizenid,
    })

    return true
end

RegisterNetEvent('cobalt_housing:server:answerOffer', function(accepted)
    local buyerId <const> = source
    local sale <const> = offers[buyerId]

    if not sale then return end

    offers[buyerId] = nil

    if accepted ~= true then
        Players.notify(sale.realtor, locale('realtor.offer_declined'), 'error')
        return
    end

    if sale.expires < os.time() then
        Players.notify(buyerId, locale('realtor.offer_expired'), 'error')
        return
    end

    local realtor <const> = Players.realtor(sale.realtor)

    if realtor?.PlayerData.citizenid ~= sale.realtorCitizenid or not Players.near(buyerId, Players.coords(sale.realtor), config.buyerRange) then
        Players.notify(buyerId, locale('realtor.realtor_absent'), 'error')
        return
    end

    local sold <const>, err <const> = completeSale(buyerId, sale)

    if not sold then
        Players.notify(buyerId, err --[[@as string]], 'error')
        Players.notify(sale.realtor, locale('realtor.sale_failed'), 'error')
        return
    end

    Players.notify(buyerId, locale('realtor.bought'), 'success')
    Players.notify(sale.realtor, locale('realtor.sold'), 'success')
    TriggerClientEvent('cobalt_housing:client:ownedChanged', buyerId)
end)

AddEventHandler('playerDropped', function()
    offers[source] = nil
end)

lib.callback.register('cobalt_housing:realtor:list', list)
lib.callback.register('cobalt_housing:realtor:save', save)
lib.callback.register('cobalt_housing:realtor:delete', remove)
lib.callback.register('cobalt_housing:realtor:preview', preview)
lib.callback.register('cobalt_housing:realtor:buyers', buyers)
lib.callback.register('cobalt_housing:realtor:offer', offer)
