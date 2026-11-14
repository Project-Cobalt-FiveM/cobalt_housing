---@class ShellStyle
---@field export string
---@field theme string

---@class Shell
---@field label string
---@field category string
---@field entry vector4
---@field stash? vector3
---@field wardrobe? vector3
---@field style? ShellStyle

---@type table<string, Shell>
local shells <const> = {
    motel_room = {
        label = locale('shells.motel_room'),
        category = locale('shells.categories.starter'),
        entry = vector4(151.39, -1007.91, -99.0, 357.0),
        stash = vector3(-0.1, 4.37, 0.0),
        wardrobe = vector3(0.39, 6.41, 0.0),},
    apartment_low = {
        label = locale('shells.apartment_low'),
        category = locale('shells.categories.apartment'),
        entry = vector4(266.06, -1007.53, -101.01, 0.0),},
    apartment_mid = {
        label = locale('shells.apartment_mid'),
        category = locale('shells.categories.apartment'),
        entry = vector4(346.49, -1012.87, -99.2, 0.0),},
    apartment_integrity_30 = {
        label = locale('shells.apartment_integrity_30'),
        category = locale('shells.categories.apartment'),
        entry = vector4(-35.31, -580.42, 88.71, 0.0),},
    apartment_dell_perro_7 = {
        label = locale('shells.apartment_dell_perro_7'),
        category = locale('shells.categories.apartment'),
        entry = vector4(-1477.14, -538.75, 55.53, 0.0),},
    apartment_dell_perro_4 = {
        label = locale('shells.apartment_dell_perro_4'),
        category = locale('shells.categories.apartment'),
        entry = vector4(-1468.14, -541.82, 73.44, 0.0),},
    apartment_richards_majestic_2 = {
        label = locale('shells.apartment_richards_majestic_2'),
        category = locale('shells.categories.apartment'),
        entry = vector4(-915.81, -379.43, 113.67, 0.0),},
    apartment_tinsel_towers_42 = {
        label = locale('shells.apartment_tinsel_towers_42'),
        category = locale('shells.categories.apartment'),
        entry = vector4(-614.86, 40.68, 97.6, 0.0),},
    apartment_eclipse_towers_3 = {
        label = locale('shells.apartment_eclipse_towers_3'),
        category = locale('shells.categories.apartment'),
        entry = vector4(-773.41, 341.77, 211.4, 0.0),},
    apartment_integrity_28 = {
        label = locale('shells.apartment_integrity_28'),
        category = locale('shells.categories.apartment'),
        entry = vector4(-18.08, -583.67, 79.47, 0.0),},
    apartment_high_life_6 = {
        label = locale('shells.apartment_high_life_6'),
        category = locale('shells.categories.apartment'),
        entry = vector4(-609.57, 51.28, -183.98, 0.0),},
    house_wild_oats_3655 = {
        label = locale('shells.house_wild_oats_3655'),
        category = locale('shells.categories.house'),
        entry = vector4(-169.29, 486.49, 137.44, 0.0),},
    house_north_conker_2044 = {
        label = locale('shells.house_north_conker_2044'),
        category = locale('shells.categories.house'),
        entry = vector4(340.94, 437.18, 149.39, 0.0),},
    house_north_conker_2045 = {
        label = locale('shells.house_north_conker_2045'),
        category = locale('shells.categories.house'),
        entry = vector4(373.02, 416.11, 145.7, 0.0),},
    house_hillcrest_2862 = {
        label = locale('shells.house_hillcrest_2862'),
        category = locale('shells.categories.house'),
        entry = vector4(-676.13, 588.61, 145.17, 0.0),},
    house_hillcrest_2868 = {
        label = locale('shells.house_hillcrest_2868'),
        category = locale('shells.categories.house'),
        entry = vector4(-763.11, 615.91, 144.14, 0.0),},
    house_hillcrest_2874 = {
        label = locale('shells.house_hillcrest_2874'),
        category = locale('shells.categories.house'),
        entry = vector4(-857.8, 682.56, 152.65, 0.0),},
    house_whispymound_2677 = {
        label = locale('shells.house_whispymound_2677'),
        category = locale('shells.categories.house'),
        entry = vector4(120.5, 549.95, 184.1, 0.0),},
    house_mad_wayne_2133 = {
        label = locale('shells.house_mad_wayne_2133'),
        category = locale('shells.categories.house'),
        entry = vector4(-1288.0, 440.75, 97.69, 0.0),},
    penthouse_diamond = {
        label = locale('shells.penthouse_diamond'),
        category = locale('shells.categories.penthouse'),
        entry = vector4(976.64, 70.3, 115.16, 0.0),},
    mansion_vinewood = {
        label = locale('shells.mansion_vinewood'),
        category = locale('shells.categories.mansion'),
        entry = vector4(543.85, 712.75, 201.0, 0.0),},
    mansion_richman = {
        label = locale('shells.mansion_richman'),
        category = locale('shells.categories.mansion'),
        entry = vector4(-1630.43, 470.85, 128.0, 0.0),},
    mansion_tongva = {
        label = locale('shells.mansion_tongva'),
        category = locale('shells.categories.mansion'),
        entry = vector4(-2601.71, 1874.83, 166.0, 0.0),},
    story_michael = {
        label = locale('shells.story_michael'),
        category = locale('shells.categories.story_house'),
        entry = vector4(-802.31, 175.06, 72.84, 0.0),},
    story_franklin_hills = {
        label = locale('shells.story_franklin_hills'),
        category = locale('shells.categories.story_house'),
        entry = vector4(7.72, 537.62, 176.03, 0.0),},
    story_franklin_aunt = {
        label = locale('shells.story_franklin_aunt'),
        category = locale('shells.categories.story_house'),
        entry = vector4(-9.97, -1438.54, 31.1, 0.0),},
    story_floyd = {
        label = locale('shells.story_floyd'),
        category = locale('shells.categories.story_house'),
        entry = vector4(-1150.7, -1520.71, 10.63, 0.0),},
    story_trevor = {
        label = locale('shells.story_trevor'),
        category = locale('shells.categories.story_house'),
        entry = vector4(1985.48, 3828.77, 32.5, 0.0),},
    clubhouse_small = {
        label = locale('shells.clubhouse_small'),
        category = locale('shells.categories.clubhouse'),
        entry = vector4(1107.04, -3157.4, -37.52, 0.0),},
    clubhouse_large = {
        label = locale('shells.clubhouse_large'),
        category = locale('shells.categories.clubhouse'),
        entry = vector4(998.48, -3164.71, -38.91, 0.0),},
}

local penthouseThemes <const> = { 'modern', 'moody', 'vibrant', 'sharp', 'monochrome', 'seductive', 'regal', 'aqua' }

local penthouses <const> = {
    { export = 'GetExecApartment1Object', entry = vector4(-787.78, 334.92, 215.84, 0.0) },
    { export = 'GetExecApartment2Object', entry = vector4(-773.23, 322.83, 194.89, 0.0) },
    { export = 'GetExecApartment3Object', entry = vector4(-787.78, 334.92, 186.11, 0.0) },
}

for suite, penthouse in ipairs(penthouses) do
    for _, theme in ipairs(penthouseThemes) do
        shells[('penthouse_eclipse_%d_%s'):format(suite, theme)] = {
            label = locale('shells.penthouse_eclipse', suite, locale(('shells.themes.%s'):format(theme))),
            category = locale('shells.categories.penthouse'),
            entry = penthouse.entry,
            style = { export = penthouse.export, theme = theme },
        }
    end
end

return shells
