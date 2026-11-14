local config <const> = require 'config'

local Cobalt <const> = exports.cobalt_core:GetCoreObject()

local Players <const> = {}

---@param source integer
---@return table?
function Players.get(source)
    return Cobalt.Functions.GetPlayer(source)
end

---@param source integer
---@return table?
function Players.realtor(source)
    local player <const> = Cobalt.Functions.GetPlayer(source)
    if player?.PlayerData.job?.name ~= config.job then return nil end

    return player
end

---@param source integer
---@return vector3
function Players.coords(source)
    return GetEntityCoords(GetPlayerPed(source))
end

---@param source integer
---@param coords vector3 | vector4
---@param range number
---@return boolean
function Players.near(source, coords, range)
    return #(Players.coords(source) - coords.xyz) <= range
end

---@param player table
---@return string
function Players.name(player)
    return exports.cobalt_core:GetName(player.PlayerData.source) or locale('players.unknown_name')
end

---@param source integer
---@param description string
---@param kind? 'success' | 'error' | 'inform'
function Players.notify(source, description, kind)
    exports.cobalt_core:Notify(source, { title = locale('notify.title'), description = description, type = kind or 'inform' })
end

---@param source integer
---@param bucket integer
function Players.setBucket(source, bucket)
    Cobalt.Functions.SetPlayerBucket(source, bucket)
end

return Players
