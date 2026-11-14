require 'client.properties'
require 'client.starter'
require 'client.creator'

local Interior <const> = require 'client.interior'

---@param keepFaded boolean
---@param done fun(entered: boolean)
AddEventHandler('cobalt_housing:client:enterStarter', function(keepFaded, done)
    done(Interior.enterStarter(keepFaded == true))
end)
