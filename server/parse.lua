local config <const> = require 'config'
local shells <const> = require 'shared.shells'
local Zone <const> = require 'shared.zone'

local MAX_POINTS <const> = 32
local MAX_SIZE <const> = 250.0

local Parse <const> = {}

---@param value unknown
---@return number?
local function finite(value)
    if type(value) ~= 'number' or value ~= value or value == math.huge or value == -math.huge then return nil end

    return value
end

---@param value unknown
---@return vector3?
local function vec3(value)
    if type(value) ~= 'table' then return nil end

    local x <const>, y <const>, z <const> = finite(value.x), finite(value.y), finite(value.z)

    if not x or not y or not z then return nil end

    return vector3(x, y, z)
end

---@param value unknown
---@return vector4?
local function vec4(value)
    local position <const> = vec3(value)
    local heading <const> = type(value) == 'table' and finite(value.w) or nil

    if not position or not heading then return nil end

    return vector4(position.x, position.y, position.z, heading % 360.0)
end

---@param value unknown
---@return PropertyZone?, string?
local function zone(value)
    if type(value) ~= 'table' then return nil, locale('parse.zone_malformed') end

    if value.kind == 'box' then
        local coords <const>, size <const>, rotation <const> = vec3(value.coords), vec3(value.size), finite(value.rotation)

        if not coords or not size or not rotation then return nil, locale('parse.box_malformed') end
        if math.min(size.x, size.y, size.z) < 1.0 or math.max(size.x, size.y, size.z) > MAX_SIZE then
            return nil, locale('parse.box_size')
        end

        return { kind = 'box', coords = coords, size = size, rotation = rotation % 360.0 }
    end

    if value.kind ~= 'poly' or type(value.points) ~= 'table' then return nil, locale('parse.zone_malformed') end

    local count <const> = #value.points
    local thickness <const> = finite(value.thickness)

    if count < 3 or count > MAX_POINTS then return nil, locale('parse.polygon_points') end
    if not thickness or thickness < 1.0 or thickness > MAX_SIZE then return nil, locale('parse.zone_height') end

    local points <const> = {}

    for i = 1, count do
        points[i] = vec3(value.points[i])

        if not points[i] then return nil, locale('parse.polygon_point_malformed') end
    end

    return { kind = 'poly', points = points, thickness = thickness }
end

---@param input unknown
---@param origin vector3
---@return PropertyDraft?, string?
function Parse.draft(input, origin)
    if type(input) ~= 'table' then return nil, locale('parse.property_malformed') end

    local name <const> = type(input.name) == 'string' and input.name:gsub('^%s+', ''):gsub('%s+$', '') or ''
    local price <const> = math.tointeger(input.price)

    if #name < 1 or #name > 64 then return nil, locale('parse.name_length') end
    if not price or price < config.minPrice or price > config.maxPrice then return nil, locale('parse.price_range') end
    if type(input.shell) ~= 'string' or not shells[input.shell] then return nil, locale('parse.pick_shell') end

    local door <const> = vec4(input.door)

    if not door then return nil, locale('parse.place_door') end
    if #(door.xyz - origin) > config.maxPlacementDistance then return nil, locale('parse.stand_closer') end

    local garage

    if input.garage ~= nil then
        garage = vec4(input.garage)

        if not garage then return nil, locale('parse.garage_malformed') end
        if #(garage.xyz - door.xyz) > config.maxPlacementDistance then return nil, locale('parse.garage_too_far') end
    end

    local propertyZone

    if input.zone ~= nil then
        local err
        propertyZone, err = zone(input.zone)

        if not propertyZone then return nil, err end
        if not Zone.contains(propertyZone, door.xyz) then return nil, locale('parse.door_outside_zone') end
        if garage and not Zone.contains(propertyZone, garage.xyz) then return nil, locale('parse.garage_outside_zone') end
    end

    return {
        name = name,
        price = price,
        shell = input.shell,
        door = door,
        zone = propertyZone,
        garage = garage,
    }
end

return Parse
