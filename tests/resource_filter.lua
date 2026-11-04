-- Run from the AddOns directory with Fengari or another Lua interpreter.
local function widget()
    local object = {scripts = {}}
    return setmetatable(object, {__index = function(_, key)
        if key == "selected" or key == "areaFilter" or key == "areaFilterZone" then return nil end
        if key == "CreateFontString" or key == "CreateTexture" then
            return function() return widget() end
        end
        if key == "SetScript" then
            return function(self, event, handler) self.scripts[event] = handler end
        end
        if key == "SetText" then
            return function(self, value) self.text = value end
        end
        if key == "GetText" then
            return function(self) return rawget(self, "text") end
        end
        if key == "Show" then
            return function(self) self.shown = true end
        end
        if key == "Hide" then
            return function(self) self.shown = false end
        end
        if key == "SetShown" then
            return function(self, value) self.shown = value end
        end
        if key == "IsShown" then
            return function(self) return self.shown or false end
        end
        return function() end
    end})
end

UIParent = widget()
CreateFrame = function() return widget() end
GatherTogetherL = function(key, value) return key .. (value and (" " .. value) or "") end
C_Map = {
    GetMapArtLayers = function() return {{layerWidth=1002, layerHeight=668, tileWidth=256, tileHeight=256}} end,
    GetMapArtLayerTextures = function() return {1, 2} end,
}

assert(loadfile("GatherTogether/UI.lua"))()

local zoneA, zoneB = {en="A", mapID=1}, {en="B", mapID=2}
local areas = {
    [1] = {
        {x=0.2, y=0.2, rx=0.05, ry=0.05, fish={10}},
        {x=0.4, y=0.4, rx=0.05, ry=0.05, fish={20}},
        {x=0.6, y=0.6, rx=0.05, ry=0.05, fish={10, 20}},
    },
    [2] = {{x=0.5, y=0.5, rx=0.05, ry=0.05, fish={20}}},
}
local guide = GatherTogetherUI.Create({positions={}, mode="ore"}, {zoneA, zoneB}, {
    current = function() return zoneA end,
    name = function(zone) return zone.en end,
    nameByEnglish = function(name) return name end,
    skill = function() return 100, 0 end,
    zoneSkill = function() return 1, 1 end,
    has = function() return true end,
    matches = function() return true end,
    entries = function(zone)
        if zone == zoneB then return {{id=20, item=20, name="B"}} end
        return {{id=10, item=10, name="A"}, {id=20, item=20, name="B"}}
    end,
    areas = function(zone) return areas[zone.mapID] end,
    icon = function() return "icon" end,
    itemName = function(id) return tostring(id) end,
})

local function shownAreas()
    local result = {}
    for _, button in ipairs(guide.mapAreas) do
        if button:IsShown() then result[#result + 1] = button.area end
    end
    return result
end

guide:Refresh()
assert(#shownAreas() == 3)
guide.fishRows[1].scripts.OnClick(guide.fishRows[1])
assert(guide.areaFilter == 10 and #shownAreas() == 2)
for _, area in ipairs(shownAreas()) do
    assert(area.fish[1] == 10)
end
guide.fishRows[2].scripts.OnClick(guide.fishRows[2])
assert(guide.areaFilter == 20 and #shownAreas() == 2)
guide.fishRows[2].scripts.OnClick(guide.fishRows[2])
assert(guide.areaFilter == nil and #shownAreas() == 3)
guide.fishRows[1].scripts.OnClick(guide.fishRows[1])
guide.selected = zoneB
guide:Refresh()
assert(guide.areaFilter == nil and #shownAreas() == 1)
guide.fishRows[1].scripts.OnClick(guide.fishRows[1])
guide:SetMode("herb")
assert(guide.areaFilter == nil and #shownAreas() == 3)
print("GatherTogether resource filter OK")
