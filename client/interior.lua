local shells <const> = require 'shared.shells'

local INTERACT <const> = 38
local MANAGE <const> = 47
local FADE_MS <const> = 300
local RESUME_RANGE <const> = 80.0

local Interior <const> = {}

---@type CPoint[]
local points <const> = {}
---@type InteriorView?
local current
---@type promise?
local exited

---@param style ShellStyle
local function applyStyle(style)
    if GetResourceState('bob74_ipl') ~= 'started' then return end

    local ok <const>, err <const> = pcall(function()
        local object <const> = exports.bob74_ipl[style.export]()
        object.Style.Set(object.Style.Theme[style.theme], true)
    end)

    if not ok then lib.print.warn(('Could not apply %s %s: %s'):format(style.export, style.theme, err)) end
end

---@param coords vector4 | vector3
---@param heading? number
---@param keepFaded? boolean
local function teleport(coords, heading, keepFaded)
    DoScreenFadeOut(FADE_MS)
    Wait(FADE_MS)

    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    SetEntityCoords(cache.ped, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(cache.ped, heading or 0.0)

    local deadline <const> = GetGameTimer() + 5000

    while not HasCollisionLoadedAroundEntity(cache.ped) and GetGameTimer() < deadline do
        Wait(50)
    end

    if not keepFaded then DoScreenFadeIn(FADE_MS) end
end

---@param description string
---@param kind? 'success' | 'error'
local function notify(description, kind)
    exports.cobalt_core:Notify({ title = locale('notify.title'), description = description, type = kind or 'error' })
end

local using = false

local function clearPoints()
    for _, point in ipairs(points) do
        point:remove()
    end

    table.wipe(points)
    exports.cobalt_core:HideTextUI()
end

local function resolveExit()
    if not exited then return end

    exited:resolve(true)
    exited = nil
end

local function drop()
    clearPoints()
    current = nil
    resolveExit()
end

---@param coords vector3
---@param prompt string
---@param onUse fun()
---@param onManage? fun()
local function addPoint(coords, prompt, onUse, onManage)
    points[#points + 1] = lib.points.new({
        coords = coords,
        distance = 1.5,
        onEnter = function()
            exports.cobalt_core:ShowTextUI(prompt)
        end,
        onExit = function()
            exports.cobalt_core:HideTextUI()
        end,
        nearby = function()
            DrawMarker(
                2,
                coords.x, coords.y, coords.z + 0.3,
                0.0, 0.0, 0.0,
                180.0, 0.0, 0.0,
                0.2, 0.2, 0.2,
                250, 250, 250, 255,
                false, true, 2, false, nil, nil, false
            )

            if IsControlJustReleased(0, INTERACT) and not using then
                using = true

                CreateThread(function()
                    pcall(onUse)
                    using = false
                end)
            end
            if onManage and IsControlJustReleased(0, MANAGE) then onManage() end
        end,
    })
end

local function openWardrobe()
    exports.cobalt_core:RegisterContext({
        id = 'cobalt_housing_wardrobe',
        title = locale('interior.wardrobe.title'),
        options = {
            {
                title = locale('interior.wardrobe.outfits'),
                icon = 'shirt',
                onSelect = function() TriggerEvent('qb-clothing:client:openOutfitMenu') end,
            },
            {
                title = locale('interior.wardrobe.change_clothes'),
                icon = 'user-gear',
                onSelect = function() TriggerEvent('qb-clothing:client:openMenu') end,
            },
        },
    })
    exports.cobalt_core:ShowContext('cobalt_housing_wardrobe')
end

local function openStash()
    if not lib.callback.await('cobalt_housing:openStash', 500) then
        notify(locale('interior.stash_out_of_reach'))
    end
end

local build

---@param kind FurnitureKind
local function place(kind)
    local view <const> = lib.callback.await('cobalt_housing:placeFurniture', 500, kind)

    if not view then
        notify(locale('interior.furnish_owned_only'))
        return
    end

    build(view)
    notify(kind == 'stash' and locale('interior.stash_placed') or locale('interior.wardrobe_placed'), 'success')
end

local function openManage()
    exports.cobalt_core:RegisterContext({
        id = 'cobalt_housing_manage',
        title = locale('interior.manage.title'),
        options = {
            {
                title = locale('interior.manage.place_stash'),
                description = locale('interior.manage.place_stash_description'),
                icon = 'box',
                onSelect = function() place('stash') end,
            },
            {
                title = locale('interior.manage.place_wardrobe'),
                description = locale('interior.manage.place_wardrobe_description'),
                icon = 'shirt',
                onSelect = function() place('wardrobe') end,
            },
        },
    })
    exports.cobalt_core:ShowContext('cobalt_housing_manage')
end

---@param view InteriorView
function build(view)
    clearPoints()
    current = view

    local entry <const> = shells[view.shell].entry.xyz
    local prompt <const> = view.canFurnish and locale('interior.prompt_leave_manage') or locale('interior.prompt_leave')

    addPoint(entry, prompt, Interior.leave, view.canFurnish and openManage or nil)

    if view.stash then addPoint(view.stash, locale('interior.prompt_stash'), openStash) end
    if view.wardrobe then addPoint(view.wardrobe, locale('interior.prompt_wardrobe'), openWardrobe) end
end

---@param view? InteriorView
---@param reason? string
---@param keepFaded? boolean
---@return boolean
function Interior.enter(view, reason, keepFaded)
    if not view then
        notify(reason or locale('interior.cannot_enter'))
        return false
    end

    local shell <const> = shells[view.shell]

    if shell.style then applyStyle(shell.style) end

    exited = promise.new()
    teleport(shell.entry, shell.entry.w, keepFaded)
    build(view)

    return true
end

function Interior.leave()
    local door <const> = lib.callback.await('cobalt_housing:leave', false)

    if not door then return end

    clearPoints()
    current = nil
    teleport(door, door.w)
    resolveExit()
end

---@return boolean
function Interior.inside()
    return current ~= nil
end

---@param propertyId integer
function Interior.enterProperty(propertyId)
    Interior.enter(lib.callback.await('cobalt_housing:enter', false, propertyId))
end

---@param keepFaded? boolean
---@return boolean
function Interior.enterStarter(keepFaded)
    local view <const>, reason <const> = lib.callback.await('cobalt_housing:enterStarter', false)

    return Interior.enter(view, reason, keepFaded == true)
end

---@param shell string
function Interior.preview(shell)
    if not Interior.enter(lib.callback.await('cobalt_housing:realtor:preview', false, shell)) then return end

    Citizen.Await(exited)
end

RegisterNetEvent('cobalt_housing:client:leftInside', function(shellKey, door)
    local shell <const> = shells[shellKey]

    if not shell or not door then return end

    CreateThread(function()
        local deadline <const> = GetGameTimer() + 60000

        while not (IsScreenFadedIn() and IsEntityVisible(cache.ped)) and GetGameTimer() < deadline do
            Wait(250)
        end

        Wait(1000)

        if #(GetEntityCoords(cache.ped) - shell.entry.xyz) > RESUME_RANGE then return end

        teleport(vector3(door.x, door.y, door.z), door.w)
    end)
end)

AddStateBagChangeHandler('LoggedIn', ('player:%d'):format(cache.serverId), function(_, _, loggedIn)
    if loggedIn or not current then return end

    drop()
end)

local function leaveForHospital()
    if not current then return end

    drop()
    lib.callback.await('cobalt_housing:leave', false)
end

RegisterNetEvent('cobalt_ambulancejob:client:respawnAt', leaveForHospital)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource or not current then return end

    exports.cobalt_core:HideTextUI()
end)

return Interior
