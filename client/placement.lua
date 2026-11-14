local Zone <const> = require 'shared.zone'

local CONFIRM <const> = 38
local CANCEL <const> = 177
local UNDO <const> = 73
local FINISH <const> = 191
local ROTATE_LEFT <const> = 14
local ROTATE_RIGHT <const> = 15
local ROTATE_STEP <const> = 5.0
local RAY_DISTANCE <const> = 40.0
local COBALT <const> = { 80, 120, 215 }
local WHITE <const> = { 250, 250, 250 }

local Placement <const> = {}

---@return vector3?
local function aim()
    local hit <const>, _, coords <const> = lib.raycast.cam(1 | 16, 4, RAY_DISTANCE)

    return hit and coords or nil
end

local function disableControls()
    DisableControlAction(0, ROTATE_LEFT, true)
    DisableControlAction(0, ROTATE_RIGHT, true)
    DisableControlAction(0, 24, true)
    DisableControlAction(0, 25, true)
    DisableControlAction(0, 37, true)
    DisableControlAction(0, 140, true)
end

---@param coords vector3
---@param heading number
local function drawPoint(coords, heading)
    DrawMarker(
        1,
        coords.x, coords.y, coords.z - 0.02,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        0.6, 0.6, 0.15,
        COBALT[1], COBALT[2], COBALT[3], 255,
        false, false, 2, false, nil, nil, false
    )
    DrawMarker(
        3,
        coords.x, coords.y, coords.z + 0.6,
        0.0, 0.0, 0.0,
        90.0, 0.0, -heading,
        0.4, 0.4, 0.4,
        WHITE[1], WHITE[2], WHITE[3], 255,
        false, false, 2, false, nil, nil, false
    )
end

---@param from vector3
---@param to vector3
local function drawEdge(from, to)
    DrawLine(from.x, from.y, from.z, to.x, to.y, to.z, COBALT[1], COBALT[2], COBALT[3], 255)
end

---@param points vector3[]
---@param thickness number
local function drawPolygon(points, thickness)
    local count <const> = #points

    if count == 0 then return end

    local half <const> = thickness / 2
    local base <const> = Zone.baseHeight(points)

    for i = 1, count do
        local a <const>, b <const> = points[i], points[i % count + 1]
        local lowA <const>, lowB <const> = vector3(a.x, a.y, base - half), vector3(b.x, b.y, base - half)
        local highA <const>, highB <const> = vector3(a.x, a.y, base + half), vector3(b.x, b.y, base + half)

        if count > 1 then
            drawEdge(lowA, lowB)
            drawEdge(highA, highB)
        end

        drawEdge(lowA, highA)
    end
end

---@param target string
---@param initialHeading? number
---@return vector4?
function Placement.point(target, initialHeading)
    local heading = initialHeading or (GetGameplayCamRot(2).z + 180.0) % 360.0

    exports.cobalt_core:ShowTextUI(locale('placement.point_prompt', target))

    while true do
        Wait(0)
        disableControls()

        local coords <const> = aim()

        if IsDisabledControlPressed(0, ROTATE_LEFT) then heading = (heading + ROTATE_STEP) % 360.0 end
        if IsDisabledControlPressed(0, ROTATE_RIGHT) then heading = (heading - ROTATE_STEP) % 360.0 end

        if coords then drawPoint(coords, heading) end

        if IsControlJustReleased(0, CANCEL) then
            exports.cobalt_core:HideTextUI()
            return nil
        end

        if coords and IsControlJustReleased(0, CONFIRM) then
            exports.cobalt_core:HideTextUI()
            return vector4(coords.x, coords.y, coords.z, heading)
        end
    end
end

---@param thickness number
---@return vector3[]?
function Placement.polygon(thickness)
    local points <const> = {}

    exports.cobalt_core:ShowTextUI(locale('placement.polygon_prompt'))

    while true do
        Wait(0)
        disableControls()

        local coords <const> = aim()

        if coords then
            drawPoint(coords, 0.0)

            if #points > 0 then drawEdge(points[#points], coords) end
        end

        drawPolygon(points, thickness)

        if IsControlJustReleased(0, CANCEL) then
            exports.cobalt_core:HideTextUI()
            return nil
        end

        if coords and IsControlJustReleased(0, CONFIRM) and #points < 32 then points[#points + 1] = coords end
        if IsControlJustReleased(0, UNDO) then points[#points] = nil end

        if IsControlJustReleased(0, FINISH) and #points >= 3 then
            exports.cobalt_core:HideTextUI()
            return points
        end
    end
end

return Placement
