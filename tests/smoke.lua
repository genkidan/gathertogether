-- Run from the AddOns directory with a Lua interpreter (for example Fengari).
local eventFrame
local function widget()
    local object = {scripts = {}}
    return setmetatable(object, {__index = function(_, key)
        if key == "selected" or key == "areaFilter" or key == "areaFilterZone" then return nil end
        if key == "CreateFontString" or key == "CreateTexture" then return function() return widget() end end
        if key == "RegisterEvent" then return function(self, event)
            assert(event ~= "UNIT_SPELLCAST_CHANNEL_INTERRUPTED", "Unknown event on Forever client")
            if event == "ADDON_LOADED" then eventFrame = self end
        end end
        if key == "SetScript" then return function(self, event, handler)
            self.scripts[event] = handler
        end end
        if key == "SetText" then return function(self, value) self.text = value end end
        if key == "GetText" then return function(self) return rawget(self, "text") end end
        if key == "SetShown" then return function(self, value) self.shown = value end end
        if key == "Show" then return function(self) self.shown = true end end
        if key == "Hide" then return function(self) self.shown = false end end
        if key == "GetStringHeight" then return function() return 120 end end
        if key == "IsShown" then return function(self) return self.shown or false end end
        if key == "GetWidth" then return function() return 140 end end
        if key == "GetHeight" then return function() return 139 end end
        if key == "GetFrameLevel" then return function() return 1 end end
        return function() end
    end})
end

UIParent = widget()
Minimap = widget()
CreateFrame = function(_, name)
    local frame = widget()
    if name then _G[name] = frame end
    return frame
end
GetLocale = function() return "frFR" end
GetZoneText = function() return "Les Tarides" end
GetSubZoneText = function() return "" end
GetProfessions = function() return 1, 2, 3, 4 end
GetProfessionInfo = function(index)
    if index == 1 then return "Minage", nil, 100, 150, 0, 0, 186, 5 end
    if index == 2 then return "Herboristerie", nil, 80, 150, 0, 0, 182, 0 end
    if index == 3 then return "Dépeçage", nil, 60, 150, 0, 0, 393, 10 end
    return "Pêche", nil, 22, 75, 0, 0, 356, 38
end
GetTime = function() return 100 end
GetNumLootItems = function() return 1 end
GetLootSlotLink = function() return "|Hitem:6291:0:0:0|h[Fish]|h" end
GetItemInfo = nil -- Regression: absent du client Forever au chargement.
C_Item = nil
C_Map = {
    GetMapInfo = function(id) if id == 1413 then return {name = "Les Tarides"} end end,
    GetMapArtID = function() return 1206 end,
    GetPlayerMapPosition = function() return {x=0.47, y=0.40} end,
    GetMapArtLayers = function() return {{layerWidth=1002, layerHeight=668, tileWidth=256, tileHeight=256}} end,
    GetMapArtLayerTextures = function() return {1,2,3,4,5,6,7,8,9,10,11,12} end,
}
GetSpellInfo = nil
UnitChannelInfo = function() return nil end
DEFAULT_CHAT_FRAME = {AddMessage = function() end}
SlashCmdList = {}
C_Timer = {After = function(_, callback) callback() end}
local sound = {Sound_EnableSFX = "0", Sound_SFXVolume = "0.4"}
GetCVar = function(key) return sound[key] end
SetCVar = function(key, value) sound[key] = value end

assert(loadfile("GatherTogether/Data.lua"))()
assert(loadfile("GatherTogether/FishData.lua"))()
assert(loadfile("GatherTogether/GatheringData.lua"))()
assert(loadfile("GatherTogether/SkinningData.lua"))()
assert(loadfile("GatherTogether/ClothData.lua"))()
assert(loadfile("GatherTogether/ClothAreas.lua"))()
assert(loadfile("GatherTogether/FishingAreas.lua"))()
assert(loadfile("GatherTogether/ReportedAreas.lua"))()
assert(#GatherTogetherFishingAreas[1413] > 0)
assert(#GatherTogetherReportedAreas[1426] > 0) -- Dun Morogh had no bundled school area.
assert(#GatherTogetherZones == 57)
assert(#GatherTogetherAllZones == 60)
assert(#GatherTogetherCloth == 7)
assert(#GatherTogetherClothAreas[1413] > 0)
assert(#GatherTogetherGathering.areas.ore[1411] > 0)
assert(#GatherTogetherGathering.areas.herb[1411] > 0)
for _, zone in ipairs(GatherTogetherZones) do assert(zone.mapID, zone.en .. " has no map") end
for _, locale in ipairs({"enUS","enGB","frFR","deDE","esES","esMX","itIT","ptBR","ruRU","koKR","zhCN","zhTW"}) do
    GetLocale = function() return locale end
    assert(loadfile("GatherTogether/Localization.lua"))()
    assert(GatherTogetherL("LOCATIONS") ~= "LOCATIONS", locale)
    assert(GatherTogetherL("REGIONAL", "Test") ~= "REGIONAL", locale)
    for _, key in ipairs({"SPECIAL", "COND_NIGHTFIN", "SEARCH_FISH", "NO_MATCH", "FISHING_AREA", "AREA_ESTIMATE", "AREA_OBSERVED", "AREA_REPORTED", "MINING", "HERBALISM", "SKINNING", "GATHERING", "RESOURCES", "SEARCH_RESOURCE", "REQUIRED_SKILL", "BEAST_LEVELS", "SKIN_SKILL", "NO_COORDS"}) do
        assert(GatherTogetherL(key) ~= key, locale .. " missing " .. key)
    end
end
GetLocale = function() return "frFR" end
assert(loadfile("GatherTogether/Localization.lua"))()
assert(loadfile("GatherTogether/MapOverlays.lua"))()
assert(GatherTogetherMapOverlays[1206])
assert(loadfile("GatherTogether/UI.lua"))()
assert(loadfile("GatherTogether/Minimap.lua"))()
assert(loadfile("GatherTogether/Core.lua"))("GatherTogether")
assert(eventFrame and eventFrame.scripts.OnEvent)
eventFrame.scripts.OnEvent(eventFrame, "ADDON_LOADED", "GatherTogether")
assert(type(SlashCmdList.GATHERTOGETHER) == "function")
assert(GatherTogetherMini.title.text:find("22 (+38)", 1, true))
assert(GatherTogetherMini.info.text:find("Conditions particulières", 1, true))
assert(not GatherTogetherMini.info.text:find("Appât", 1, true))
assert(not GatherTogetherMini.info.text:find("Toi", 1, true))
SlashCmdList.GATHERTOGETHER("")
assert(GatherTogetherGuide.skillTitle.text:find("22 (+38)", 1, true))
GatherTogetherGuide:SetMode("ore")
assert(GatherTogetherGuide.mode == "ore")
assert(GatherTogetherGuide.skillTitle.text:find("Minage 100 (+5)", 1, true))
assert(GatherTogetherGuide.fishRows[1].text.text ~= "")
eventFrame.scripts.OnEvent(eventFrame, "UNIT_SPELLCAST_START", "player", "cast", 2575)
assert(GatherTogetherMini:IsShown())
assert(GatherTogetherMini.info.text:find("Ressources", 1, true))
eventFrame.scripts.OnEvent(eventFrame, "UNIT_SPELLCAST_STOP", "player", "cast", 2575)
assert(not GatherTogetherMini:IsShown())
GatherTogetherGuide:SetMode("herb")
assert(GatherTogetherGuide.mode == "herb")
assert(GatherTogetherGuide.skillTitle.text:find("Herboristerie 80 (+0)", 1, true))
GatherTogetherGuide:SetMode("skinning")
assert(GatherTogetherGuide.mode == "skinning")
assert(GatherTogetherGuide.skillTitle.text:find("Dépeçage 60 (+10)", 1, true))
GatherTogetherGuide:SetMode("cloth")
assert(GatherTogetherGuide.mode == "cloth")
assert(GatherTogetherGuide.zoneTitle.text == "Les Tarides")
assert(GatherTogetherGuide.fishRows[1].text.text ~= "")
assert(#GatherTogetherGuide.mapAreas > 0)
assert(GatherTogetherGuide.mapHint.text:find("butin", 1, true))
local selectedCloth = GatherTogetherGuide.fishRows[1].areaID
GatherTogetherGuide.fishRows[1].scripts.OnClick(GatherTogetherGuide.fishRows[1])
assert(GatherTogetherGuide.areaFilter == selectedCloth)
for _, area in ipairs(GatherTogetherGuide.mapAreas) do
    if area:IsShown() then
        local found = false
        for _, id in ipairs(area.area.fish) do if id == selectedCloth then found = true end end
        assert(found, "Cloth filter showed an unrelated map area")
    end
end
assert(GatherTogetherGuide.skillTitle.text == "")
assert(GatherTogetherGuide.subtitle.text == "Lieux de butin des tissus")
assert(GatherTogetherMini.title.text:find("Pêche 22", 1, true))
GatherTogetherGuide:SetMode("fishing")
assert(GatherTogetherMinimap.button)
GatherTogetherMinimap.button.scripts.OnClick(GatherTogetherMinimap.button)
for _, row in ipairs(GatherTogetherGuide.zoneRows) do row.frame.scripts.OnClick(row.frame) end
for _, row in ipairs(GatherTogetherGuide.zoneRows) do
    if row.zone.en == "The Barrens" then row.frame.scripts.OnClick(row.frame) end
end
assert(GatherTogetherGuide.fishRows[1].condition.text ~= "")
assert(#GatherTogetherGuide.mapAreas > 0)
local school = {x=0.484, y=0.229, rx=0.055, ry=0.075, fish={999999}}
local barrensSchools = GatherTogetherFishingAreas[1413]
barrensSchools[#barrensSchools + 1] = school
GatherTogetherGuide:Refresh()
local schoolVisible = false
for _, button in ipairs(GatherTogetherGuide.mapAreas) do
    if button:IsShown() and button.area == school then schoolVisible = true end
end
assert(schoolVisible, "A nearby reported area must not hide a different school resource")
barrensSchools[#barrensSchools] = nil
for _, row in ipairs(GatherTogetherGuide.zoneRows) do
    if row.zone.en == "Dun Morogh" then row.frame.scripts.OnClick(row.frame) end
end
assert(not GatherTogetherGuide.mapHint.text:find("Aucune zone", 1, true))
GatherTogetherFishSearch:SetText("Deviate")
GatherTogetherFishSearch.scripts.OnTextChanged(GatherTogetherFishSearch)
local barrensVisible, dunVisible
for _, row in ipairs(GatherTogetherGuide.zoneRows) do
    if row.zone.en == "The Barrens" then barrensVisible = row.frame:IsShown() end
    if row.zone.en == "Dun Morogh" then dunVisible = row.frame:IsShown() end
end
assert(barrensVisible and not dunVisible)
GatherTogetherFishSearch:SetText("")
GatherTogetherFishSearch.scripts.OnTextChanged(GatherTogetherFishSearch)
assert(#GatherTogetherGuide.mapOverlays > 0)
eventFrame.scripts.OnEvent(eventFrame, "UNIT_SPELLCAST_CHANNEL_START", "player", "cast", 7620)
assert(sound.Sound_EnableSFX == "1" and sound.Sound_SFXVolume == "1")
eventFrame.scripts.OnEvent(eventFrame, "UNIT_SPELLCAST_CHANNEL_STOP", "player", "cast", 7620)
assert(sound.Sound_EnableSFX == "0" and sound.Sound_SFXVolume == "0.4")
eventFrame.scripts.OnEvent(eventFrame, "LOOT_OPENED")
assert(GatherTogetherDB.catches["The Barrens"][6291] == 1)
assert(GatherTogetherDB.spots["The Barrens"][1].fish[1] == 6291)
print("GatherTogether smoke OK")
