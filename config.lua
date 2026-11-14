return {
    -- Realtor job and storage
    job = 'realtor', -- job that creates, prices and sells properties; must exist in cobalt_core data/jobs.lua
    stash = { -- each property's stash
        slots = 150, -- cells, laid out 5 to a row
        maxWeight = 400000, -- most it holds, in grams
    },

    -- Ranges, in meters
    doorRange = 2.5, -- how close to a front door the enter prompt shows
    doorCheckRange = 5.0, -- how far from the door the server still lets a player enter
    furnitureRange = 2.0, -- how close to a stash or wardrobe a player must be to use it
    buyerRange = 5.0, -- how close a buyer must stand to receive a realtor's offer
    maxPlacementDistance = 150.0, -- how far from the door a realtor can place doors and furniture

    -- Sales
    offerSeconds = 60, -- seconds a buyer has to accept an offer
    minPrice = 1000, -- lowest price a realtor can set, in dollars
    maxPrice = 100000000, -- highest price a realtor can set, in dollars

    -- Starter rooms (the rooms themselves are set in cobalt_core config/shared.lua)
    starterPickSeconds = 600, -- seconds a character with no starter room has to open the room picker after loading in, and again to pick a room once it opens

    -- Routing buckets: each interior gets base + id so players in different homes never meet
    buckets = {
        property = 100000, -- owned properties, + property id
        starter = 200000, -- starter motel rooms, + the player's server id
        preview = 300000, -- realtor previews, + the realtor's server id
    },

    -- Map blips: sprite and colour ids from the FiveM blip reference, scale 0.0 to 1.0
    blip = {
        owned = { sprite = 40, colour = 3, scale = 0.7 }, -- properties the player owns
        forSale = { sprite = 350, colour = 0, scale = 0.6 }, -- properties on the market
        starter = { sprite = 475, colour = 3, scale = 0.7 }, -- the player's starter room
    },
}
