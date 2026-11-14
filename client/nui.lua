local Nui <const> = {}

local VECTOR_TYPES <const> = { vector2 = true, vector3 = true, vector4 = true }

local focused = false

---@param state boolean
local function setFocus(state)
    SetNuiFocus(state, state)

    if focused == state then return end

    focused = state

    if not state then return end

    CreateThread(function()
        while focused do
            DisableControlAction(0, 199, true)
            DisableControlAction(0, 200, true)
            Wait(0)
        end
    end)
end

---@param value any
---@return any
function Nui.plain(value)
    local kind <const> = type(value)

    if VECTOR_TYPES[kind] then
        return { x = value.x, y = value.y, z = kind ~= 'vector2' and value.z or nil, w = kind == 'vector4' and value.w or nil }
    end

    if kind ~= 'table' then return value end

    local copy <const> = {}

    for key, item in pairs(value) do
        copy[key] = Nui.plain(item)
    end

    return copy
end

---@type table<string, string>?
local uiStrings

---@return table<string, string>
local function uiLocales()
    if uiStrings then return uiStrings end

    local strings <const> = {}

    for key, value in pairs(lib.getLocales()) do
        if key:sub(1, 3) == 'ui.' then
            strings[key] = value
        end
    end

    uiStrings = strings

    return strings
end

---@param view 'creator' | 'starter'
---@param data table
function Nui.open(view, data)
    SendNUIMessage({ action = 'open', data = { view = view, payload = Nui.plain(data) }, locales = uiLocales() })
    setFocus(true)
end

---@param visible boolean
function Nui.setVisible(visible)
    SendNUIMessage({ action = 'visible', data = visible })
    setFocus(visible)
end

function Nui.close()
    SendNUIMessage({ action = 'close' })
    setFocus(false)
end

RegisterNUICallback('close', function(_, cb)
    cb(true)
    setFocus(false)
end)

return Nui
