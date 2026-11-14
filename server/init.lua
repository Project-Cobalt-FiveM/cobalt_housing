local Properties <const> = require 'server.properties'
local Players <const> = require 'server.players'

require 'server.occupancy'
require 'server.starter'
require 'server.realtor'

local MAX_MATCHES <const> = 25

---@class PropertySummary
---@field id integer
---@field name string
---@field shell string
---@field door vector4
---@field garage? vector4

---@param property Property
---@return PropertySummary
local function summary(property)
    return {
        id = property.id,
        name = property.name,
        shell = property.shell,
        door = property.door,
        garage = property.garage,
    }
end

---@class PropertyDetail : PropertySummary
---@field owner? string
---@field price integer
---@field zone? table

---@param property Property
---@return PropertyDetail
local function detail(property)
    local result <const> = summary(property) --[[@as PropertyDetail]]
    result.owner = property.owner
    result.price = property.price
    result.zone = property.zone

    return result
end

lib.callback.register('cobalt_housing:properties', function()
    return Properties.list()
end)

lib.callback.register('cobalt_housing:owned', function(source)
    local player <const> = Players.get(source)
    local ids <const> = {}

    if not player then return ids end

    for i, property in ipairs(Properties.ownedBy(player.PlayerData.citizenid)) do
        ids[i] = property.id
    end

    return ids
end)

exports('GetProperty', function(id)
    local property <const> = Properties.get(id)

    if not property then return nil end

    return detail(property)
end)

exports('FindProperties', function(query, limit)
    if type(query) ~= 'string' or #query < 2 then return {} end

    local matches <const> = Properties.find(query)
    local list <const> = {}

    for i = 1, math.min(#matches, math.tointeger(tonumber(limit)) or MAX_MATCHES, MAX_MATCHES) do
        list[i] = detail(matches[i])
    end

    return list
end)

exports('GetOwnedProperties', function(citizenid)
    local list <const> = {}

    for i, property in ipairs(Properties.ownedBy(citizenid)) do
        list[i] = summary(property)
    end

    return list
end)

exports('HasAccess', Properties.hasAccess)

CreateThread(Properties.load)
