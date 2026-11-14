---@meta

---@class HousingPolyZone
---@field kind 'poly'
---@field points vector3[]
---@field thickness number

---@class HousingBoxZone
---@field kind 'box'
---@field coords vector3
---@field size vector3
---@field rotation number

---@alias HousingZone HousingPolyZone|HousingBoxZone

---@class HousingPropertySummary
---@field id integer
---@field name string
---@field shell string
---@field door vector4
---@field garage? vector4

---@class HousingProperty : HousingPropertySummary
---@field owner? string citizenid
---@field price integer
---@field zone? HousingZone

---@class CobaltHousingExports
local CobaltHousingExports = {}

---**Server.** Returns a property by id, or nil when it does not exist.
---@param id integer
---@return HousingProperty?
function CobaltHousingExports:GetProperty(id) end

---**Server.** Properties whose name contains `query`, ignoring case, sorted by id. `limit` defaults to 25, which is also the most it returns. Empty when `query` is under 2 characters.
---@param query string
---@param limit? integer
---@return HousingProperty[]
function CobaltHousingExports:FindProperties(query, limit) end

---**Server.** Returns the properties a character owns.
---@param citizenid string
---@return HousingPropertySummary[]
function CobaltHousingExports:GetOwnedProperties(citizenid) end

---**Server.** Whether the character owns the property.
---@param citizenid string
---@param propertyId integer
---@return boolean
function CobaltHousingExports:HasAccess(citizenid, propertyId) end

exports.cobalt_housing = CobaltHousingExports
