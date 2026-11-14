local shells <const> = require 'shared.shells'
local Nui <const> = require 'client.nui'
local Placement <const> = require 'client.placement'
local Interior <const> = require 'client.interior'
local Properties <const> = require 'client.properties'

---@type table<string, true>
local PLACE_TARGETS <const> = { door = true, garage = true, box = true }

---@type { key: string, label: string, category: string }[]
local shellList <const> = {}

for key, shell in pairs(shells) do
    shellList[#shellList + 1] = { key = key, label = shell.label, category = shell.category }
end

table.sort(shellList, function(a, b)
    if a.category ~= b.category then return a.category < b.category end

    return a.label < b.label
end)

---@param propertyId? integer
local function open(propertyId)
    if not Properties.isRealtor() then
        exports.cobalt_core:Notify({
            title = locale('notify.title'),
            description = locale('creator.realtor_only'),
            type = 'error',
        })
        return
    end

    if Interior.inside() then return end

    local list <const> = lib.callback.await('cobalt_housing:realtor:list', false)

    if not list then return end

    Nui.open('creator', { properties = list, shells = shellList, editId = propertyId })
end

---@param fn fun(): any
---@return any
local function whileHidden(fn)
    Nui.setVisible(false)

    local result <const> = fn()

    if LocalPlayer.state.LoggedIn then
        Nui.setVisible(true)
    else
        Nui.close()
    end

    return result
end

---@param data { kind: 'door' | 'garage' | 'box' | 'poly', thickness?: number, heading?: number }
---@return table?
local function place(data)
    if data.kind == 'poly' then
        return Placement.polygon(tonumber(data.thickness) or 6.0)
    end

    local target <const> = PLACE_TARGETS[data.kind] and data.kind or 'point'

    return Placement.point(locale(('placement.targets.%s'):format(target)), tonumber(data.heading))
end

RegisterNUICallback('creator:refresh', function(_, cb)
    cb(Nui.plain(lib.callback.await('cobalt_housing:realtor:list', false) or {}))
end)

RegisterNUICallback('creator:save', function(data, cb)
    cb(lib.callback.await('cobalt_housing:realtor:save', false, data.id, data.draft))
end)

RegisterNUICallback('creator:delete', function(data, cb)
    cb(lib.callback.await('cobalt_housing:realtor:delete', false, data.id) == true)
end)

RegisterNUICallback('creator:place', function(data, cb)
    cb(Nui.plain(whileHidden(function() return place(data) end)) or false)
end)

RegisterNUICallback('creator:preview', function(data, cb)
    whileHidden(function() Interior.preview(data.shell) end)
    cb(true)
end)

RegisterNUICallback('creator:buyers', function(_, cb)
    cb(lib.callback.await('cobalt_housing:realtor:buyers', false) or {})
end)

RegisterNUICallback('creator:offer', function(data, cb)
    cb(lib.callback.await('cobalt_housing:realtor:offer', false, data.id, data.serverId))
end)

RegisterCommand('realtor', function() open() end, false)

Properties.onEdit(open)
