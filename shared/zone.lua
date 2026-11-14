---@class PropertyPolyZone
---@field kind 'poly'
---@field points vector3[]
---@field thickness number

---@class PropertyBoxZone
---@field kind 'box'
---@field coords vector3
---@field size vector3
---@field rotation number

---@alias PropertyZone PropertyPolyZone | PropertyBoxZone

local Zone <const> = {}

---@param points vector3[]
---@param x number
---@param y number
---@return boolean
local function insidePolygon(points, x, y)
    local inside = false
    local j = #points

    for i = 1, #points do
        local a <const>, b <const> = points[i], points[j]

        if (a.y > y) ~= (b.y > y) and x < (b.x - a.x) * (y - a.y) / (b.y - a.y) + a.x then
            inside = not inside
        end

        j = i
    end

    return inside
end

---@param points vector3[]
---@return number
function Zone.baseHeight(points)
    local total = 0.0

    for i = 1, #points do
        total += points[i].z
    end

    return total / #points
end

---@param zone PropertyZone
---@param point vector3
---@return boolean
function Zone.contains(zone, point)
    if zone.kind == 'box' then
        local offset <const> = point - zone.coords
        local angle <const> = math.rad(-zone.rotation)
        local x <const> = offset.x * math.cos(angle) - offset.y * math.sin(angle)
        local y <const> = offset.x * math.sin(angle) + offset.y * math.cos(angle)

        if math.abs(offset.z) > zone.size.z / 2 then return false end

        return math.abs(x) <= zone.size.x / 2 and math.abs(y) <= zone.size.y / 2
    end

    if math.abs(point.z - Zone.baseHeight(zone.points)) > zone.thickness / 2 then return false end

    return insidePolygon(zone.points, point.x, point.y)
end

return Zone
