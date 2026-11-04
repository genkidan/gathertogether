local addonName = ...
local zones = GatherTogetherAllZones or GatherTogetherZones
local fishData = GatherTogetherFishData
local fishNames = GatherTogetherFishNames
local L = GatherTogetherL
local db, guide, mini, casting, gatheringMode, lastCastAt, lastLocation, lastZoneKey, lastPosition
local resourceEntries
local savedSound
local zoneByEnglish = {}
for _, zone in ipairs(zones) do zoneByEnglish[zone.en] = zone end

local function say(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff44cceeGather Together|r : " .. message)
end

local function normalize(value)
    return (value or ""):lower():gsub("[’‘]", "'"):gsub("%s+", " ")
end

local function displayName(zone)
    if zone.areaID and C_Map and C_Map.GetAreaInfo then
        local ok, name = pcall(C_Map.GetAreaInfo, zone.areaID)
        if ok and name and name ~= "" then return name end
    end
    if not zone.mapFrom and zone.mapID and C_Map and C_Map.GetMapInfo then
        local ok, info = pcall(C_Map.GetMapInfo, zone.mapID)
        if ok and info and info.name and info.name ~= "" then return info.name end
    end
    return GetLocale() == "frFR" and zone.fr or zone.en
end

local function nameByEnglish(english)
    local zone = zoneByEnglish[english]
    return zone and displayName(zone) or english
end

local function currentLocation()
    local sub = GetSubZoneText() or ""
    local main = GetZoneText() or ""
    local subKey, mainKey = normalize(sub), normalize(main)
    for _, zone in ipairs(zones) do
        if subKey ~= "" and (subKey == normalize(displayName(zone)) or subKey == normalize(zone.fr) or subKey == normalize(zone.en)) then
            return zone, sub
        end
    end
    for _, zone in ipairs(zones) do
        if mainKey == normalize(displayName(zone)) or mainKey == normalize(zone.fr) or mainKey == normalize(zone.en) then
            return zone, main
        end
    end
    return nil, sub ~= "" and sub or main
end

local professionIDs = {fishing=356, ore=186, herb=182, skinning=393}
local function professionSkill(mode)
    if not GetProfessions or not GetProfessionInfo then return nil end
    local first, second, archaeology, fishing = GetProfessions()
    for _, index in ipairs({first or 0, second or 0, archaeology or 0, fishing or 0}) do
        if index > 0 then
            local _, _, skill, _, _, _, id, modifier = GetProfessionInfo(index)
            if tonumber(id) == professionIDs[mode or "fishing"] then
                return skill, tonumber(modifier) or 0
            end
        end
    end
    return nil
end

local function itemName(id, fallback)
    if C_Item and C_Item.GetItemNameByID then
        local ok, name = pcall(C_Item.GetItemNameByID, id)
        if ok and name then return name end
    end
    if C_Item and C_Item.GetItemInfo then
        local ok, name = pcall(C_Item.GetItemInfo, id)
        if ok and name then return name end
    end
    if GetItemInfo then
        local ok, name = pcall(GetItemInfo, id)
        if ok and name then return name end
    end
    if C_Item and C_Item.RequestLoadItemDataByID then
        pcall(C_Item.RequestLoadItemDataByID, id)
    end
    return fallback
end

local function itemIcon(id)
    if C_Item and C_Item.GetItemIconByID then
        local ok, icon = pcall(C_Item.GetItemIconByID, id)
        if ok and icon then return icon end
    end
    if C_Item and C_Item.GetItemInfoInstant then
        local ok, _, _, _, _, icon = pcall(C_Item.GetItemInfoInstant, id)
        if ok and icon then return icon end
    end
    if GetItemIcon then
        local ok, icon = pcall(GetItemIcon, id)
        if ok and icon then return icon end
    end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function fishLabel(id)
    return itemName(id, fishNames[id] or ("Objet #" .. id))
end

local function fishCondition(id)
    local key = GatherTogetherFishConditions and GatherTogetherFishConditions[id]
    return key and L(key) or nil
end

local function addFishLines(lines, zone, location, compact)
    local ids = zone and (fishData[zone.en] or (zone.fishFrom and fishData[zone.fishFrom]))
    local label = (zone and zone.fishFrom and L("FISH_PARENT") or L("FISH")) .. ": "
    if ids and #ids > 0 then
        local names = {}
        for _, id in ipairs(ids) do names[#names + 1] = fishLabel(id) end
        lines[#lines + 1] = label .. table.concat(names, ", ")
    else
        lines[#lines + 1] = L("FISH_MISSING")
    end
    local observed = db and db.catches and (db.catches[zone and zone.en or ""] or db.catches[normalize(location)])
    if observed then
        local names = {}
        for id, count in pairs(observed) do names[#names + 1] = fishLabel(id) .. " ×" .. count end
        table.sort(names)
        if #names > 0 then lines[#lines + 1] = L("CAUGHT") .. ": " .. table.concat(names, ", ") end
    end
end

local function detail(zone, location, mode)
    local lines = {}
    lines[#lines + 1] = zone and displayName(zone) or (location ~= "" and location or L("UNKNOWN"))
    if mode ~= "fishing" then
        local entries = zone and resourceEntries(zone, mode) or {}
        if #entries == 0 then
            lines[#lines + 1] = L("UNKNOWN")
        else
            lines[#lines + 1] = L("RESOURCES") .. ":"
            for _, entry in ipairs(entries) do
                lines[#lines + 1] = "• " .. entry.name .. " — " .. entry.condition
            end
        end
        if mode == "skinning" then lines[#lines + 1] = L("NO_COORDS") end
        return table.concat(lines, "\n")
    end
    if zone then
        lines[#lines + 1] = L("MIN", zone.minimum) .. " · " .. L("SAFE", zone.sure)
    else
        lines[#lines + 1] = L("SKILL") .. ": " .. L("UNKNOWN")
    end
    addFishLines(lines, zone, location, true)
    local ids = zone and (fishData[zone.en] or (zone.fishFrom and fishData[zone.fishFrom]))
    local special = {}
    if ids then
        for _, id in ipairs(ids) do
            local condition = fishCondition(id)
            if condition then special[#special + 1] = fishLabel(id) .. " — " .. condition end
        end
    end
    if #special > 0 then
        lines[#lines + 1] = L("SPECIAL") .. ":"
        for _, line in ipairs(special) do lines[#lines + 1] = "• " .. line end
    end
    return table.concat(lines, "\n")
end

local function panel(name, width, height)
    local frame = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    frame:SetSize(width, height)
    frame:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16, insets = {left = 4, right = 4, top = 4, bottom = 4}})
    frame:SetBackdropColor(0.02, 0.10, 0.16, 0.95)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint(1)
        db.positions[name] = {point, relativePoint, x, y}
    end)
    frame:SetClampedToScreen(true)
    local saved = db.positions[name]
    if saved then frame:SetPoint(saved[1], UIParent, saved[2], saved[3], saved[4]) end
    return frame
end

local function header(frame, title)
    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    label:SetPoint("TOPLEFT", 16, -14)
    label:SetText(title)
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -3, -3)
    return label
end

local function makeMini()
    mini = panel("GatherTogetherMini", 430, 300)
    if not db.positions.GatherTogetherMini then mini:SetPoint("CENTER", UIParent, "CENTER", 0, 170) end
    mini.title = header(mini, "|cff44ccee" .. L("SKILL") .. "|r")
    local scroll = CreateFrame("ScrollFrame", "GatherTogetherMiniScroll", mini, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 14, -43)
    scroll:SetPoint("BOTTOMRIGHT", -29, 39)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(373, 1)
    scroll:SetScrollChild(content)
    mini.content = content
    mini.info = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    mini.info:SetPoint("TOPLEFT", 0, 0)
    mini.info:SetWidth(368)
    mini.info:SetJustifyH("LEFT")
    mini.info:SetJustifyV("TOP")
    mini.info:SetText(L("WAITING"))
    local guideButton = CreateFrame("Button", nil, mini, "UIPanelButtonTemplate")
    guideButton:SetSize(82, 23)
    guideButton:SetPoint("BOTTOMLEFT", 12, 10)
    guideButton:SetText(L("LOCATIONS"))
    guideButton:SetScript("OnClick", function() guide:Show() end)
    mini.status = mini:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    mini.status:SetPoint("BOTTOMRIGHT", -16, 16)
    mini.status:SetText(L("WAITING"))
    mini:SetScript("OnHide", function() if not casting then db.showMini = false end end)
    mini:Hide()
end

local function updateMini()
    if not mini then return end
    local zone, location = currentLocation()
    local mode = casting and "fishing" or db.mode or "fishing"
    if mode == "cloth" then mode = "fishing" end
    local skill, bonus = professionSkill(mode)
    local title = mode == "fishing" and L("SKILL") or mode == "ore" and L("MINING")
        or mode == "herb" and L("HERBALISM") or L("SKINNING")
    if skill then
        title = bonus > 0 and L("BONUS_SKILL", title, skill, bonus) or L("BASE_SKILL", title, skill)
    end
    mini.title:SetText("|cff44ccee" .. title .. "|r")
    mini.info:SetText(detail(zone, location, mode))
    local height = mini.info:GetStringHeight()
    mini.content:SetHeight(math.max(1, (tonumber(height) or 200) + 12))
    mini.status:SetText(mode == "fishing" and (casting and L("SPLASH") or L("WAITING")) or "")
end

local function updateGuide()
    if guide then guide:Refresh() end
end

local function zoneCatches(zone)
    local result, checked = {}, {}
    for _, key in ipairs({zone.en, normalize(zone.en), normalize(zone.fr), normalize(displayName(zone))}) do
        if not checked[key] then
            checked[key] = true
            local bucket = db.catches[key]
            if bucket then
                for id, count in pairs(bucket) do result[tonumber(id) or id] = (result[tonumber(id) or id] or 0) + count end
            end
        end
    end
    return result
end

local function fishEntries(zone)
    local ids = fishData[zone.en] or (zone.fishFrom and fishData[zone.fishFrom]) or {}
    local catches, entries, seen = zoneCatches(zone), {}, {}
    for _, id in ipairs(ids) do
        entries[#entries+1] = {id=id, name=fishLabel(id), count=catches[id], condition=fishCondition(id)}
        seen[id] = true
    end
    local extras = {}
    for id in pairs(catches) do if type(id) == "number" and not seen[id] then extras[#extras+1] = id end end
    table.sort(extras)
    for _, id in ipairs(extras) do entries[#entries+1] = {id=id, name=fishLabel(id), count=catches[id], condition=fishCondition(id)} end
    return entries, zone.fishFrom and not fishData[zone.en]
end

resourceEntries = function(zone, mode)
    if mode == "fishing" then return fishEntries(zone) end
    local entries = {}
    if mode == "cloth" then
        local seen = {}
        for _, area in ipairs((GatherTogetherClothAreas and GatherTogetherClothAreas[zone.mapID]) or {}) do
            for _, id in ipairs(area.fish or {}) do seen[id] = true end
        end
        for _, cloth in ipairs(GatherTogetherCloth or {}) do
            if seen[cloth.item] then
                entries[#entries + 1] = {
                    id=cloth.item, item=cloth.item,
                    name=itemName(cloth.item, GetLocale() == "frFR" and cloth.fr or cloth.en),
                    condition=cloth.note and L(cloth.note) or L("CLOTH_BOLT", cloth.amount),
                }
            end
        end
        return entries
    end
    if mode == "skinning" then
        local leatherNames = {
            [2318]="Light Leather", [2319]="Medium Leather", [4234]="Heavy Leather",
            [4304]="Thick Leather", [8170]="Rugged Leather",
        }
        for _, band in ipairs(GatherTogetherSkinningBands or {}) do
            for _, name in ipairs(band.zones) do
                if name == zone.en then
                    entries[#entries + 1] = {
                        id=band.item, item=band.item, skill=band.skill, skillHigh=band.skillHigh,
                        name=itemName(band.item, leatherNames[band.item]) ..
                            " · " .. L("BEAST_LEVELS", band.low, band.high),
                        condition=L("SKIN_SKILL", band.skill, band.skillHigh),
                    }
                    break
                end
            end
        end
        return entries
    end
    local areas = GatherTogetherGathering and GatherTogetherGathering.areas[mode] and GatherTogetherGathering.areas[mode][zone.mapID]
    local seen = {}
    for _, area in ipairs(areas or {}) do
        for _, id in ipairs(area.fish or {}) do seen[id] = true end
    end
    for id in pairs(seen) do
        local resource = GatherTogetherGathering.resources[id]
        if resource then
            entries[#entries + 1] = {
                id=id, item=resource.item, skill=resource.skill,
                name=itemName(resource.item, resource.en),
                condition=L("REQUIRED_SKILL", resource.skill),
            }
        end
    end
    table.sort(entries, function(a, b) return a.skill == b.skill and a.name < b.name or a.skill < b.skill end)
    return entries
end

local function hasResources(zone, mode)
    if mode == "cloth" then
        local areas = GatherTogetherClothAreas and GatherTogetherClothAreas[zone.mapID]
        return areas and #areas > 0 or false
    end
    if mode == "skinning" then
        for _, band in ipairs(GatherTogetherSkinningBands or {}) do
            for _, name in ipairs(band.zones) do if name == zone.en then return true end end
        end
        return false
    end
    local areas = GatherTogetherGathering and GatherTogetherGathering.areas[mode] and GatherTogetherGathering.areas[mode][zone.mapID]
    return areas and #areas > 0 or false
end

local function zoneResourceSkill(zone, mode)
    if mode == "fishing" then return zone.minimum, zone.sure end
    if mode == "cloth" then return nil, nil end
    local lowest, highest
    for _, entry in ipairs(resourceEntries(zone, mode)) do
        lowest = math.min(lowest or entry.skill, entry.skill)
        highest = math.max(highest or entry.skill, entry.skillHigh or entry.skill)
    end
    return lowest, highest
end

local function fishingAreas(zone, mode)
    if mode == "cloth" then return (GatherTogetherClothAreas and GatherTogetherClothAreas[zone.mapID]) or {} end
    if mode ~= "fishing" then
        return mode ~= "skinning" and
            ((GatherTogetherGathering and GatherTogetherGathering.areas[mode] and GatherTogetherGathering.areas[mode][zone.mapID]) or {}) or {}
    end
    local result = {}
    for _, area in ipairs((GatherTogetherReportedAreas and GatherTogetherReportedAreas[zone.mapID]) or {}) do
        result[#result + 1] = area
    end
    for _, area in ipairs((GatherTogetherFishingAreas and GatherTogetherFishingAreas[zone.mapID]) or {}) do
        local covered = false
        for _, reported in ipairs(result) do
            if math.abs(area.x - reported.x) < 0.10 and math.abs(area.y - reported.y) < 0.10 then
                local allFishCovered = true
                for _, id in ipairs(area.fish or {}) do
                    local found = false
                    for _, reportedID in ipairs(reported.fish or {}) do
                        if id == reportedID then found = true; break end
                    end
                    if not found then allFishCovered = false; break end
                end
                if allFishCovered then covered = true; break end
            end
        end
        if not covered then result[#result + 1] = area end
    end
    for _, area in ipairs((db.spots and db.spots[zone.en]) or {}) do
        result[#result + 1] = area
    end
    return result
end

local function matchesFish(zone, query, mode)
    local lower = strlower or string.lower
    if lower(displayName(zone)):find(query, 1, true) then return true end
    if mode ~= "fishing" then
        for _, entry in ipairs(resourceEntries(zone, mode)) do
            if lower(entry.name):find(query, 1, true) then return true end
        end
        return false
    end
    local ids = fishData[zone.en] or (zone.fishFrom and fishData[zone.fishFrom]) or {}
    for _, id in ipairs(ids) do
        if lower(fishLabel(id)):find(query, 1, true)
            or (fishNames[id] and lower(fishNames[id]):find(query, 1, true)) then return true end
    end
    for id in pairs(zoneCatches(zone)) do
        if lower(fishLabel(id)):find(query, 1, true) then return true end
    end
    return false
end

local function playerMapPosition(mapID)
    if not (mapID and C_Map and C_Map.GetPlayerMapPosition) then return nil end
    local ok, point = pcall(C_Map.GetPlayerMapPosition, mapID, "player")
    if not ok or not point then return nil end
    local x, y
    if point.GetXY then x, y = point:GetXY() else x, y = point.x, point.y end
    if type(x) == "number" and type(y) == "number" and x > 0 and x < 1 and y > 0 and y < 1 then
        return {x=x, y=y}
    end
    return nil
end

local function rememberFishingArea(zone, position, id)
    if not (zone and position and fishNames[id]) then return end
    local spots = db.spots[zone.en]
    if not spots then spots = {}; db.spots[zone.en] = spots end
    local area
    for _, candidate in ipairs(spots) do
        if math.abs(candidate.x - position.x) < 0.05 and math.abs(candidate.y - position.y) < 0.06 then
            area = candidate; break
        end
    end
    if not area then
        if #spots >= 30 then return end
        area = {x=position.x, y=position.y, rx=0.055, ry=0.075, fish={}, learned=true}
        spots[#spots + 1] = area
    end
    for _, fishID in ipairs(area.fish) do if fishID == id then return end end
    area.fish[#area.fish + 1] = id
    table.sort(area.fish)
end

local function makeGuide()
    guide = GatherTogetherUI.Create(db, zones, {
        name = displayName, nameByEnglish = nameByEnglish,
        current = currentLocation, skill = professionSkill,
        entries = resourceEntries, icon = itemIcon,
        itemName = function(id, mode)
            if mode == "fishing" then return fishLabel(id) end
            if mode == "cloth" then
                for _, cloth in ipairs(GatherTogetherCloth or {}) do
                    if cloth.item == id then
                        return itemName(id, GetLocale() == "frFR" and cloth.fr or cloth.en)
                    end
                end
            end
            local resource = GatherTogetherGathering and GatherTogetherGathering.resources[id]
            return resource and (itemName(resource.item, resource.en) .. " · " .. L("REQUIRED_SKILL", resource.skill)) or tostring(id)
        end,
        areas = fishingAreas, matches = matchesFish,
        has = hasResources, zoneSkill = zoneResourceSkill,
        onMode = updateMini,
    })
end

local function boostSound()
    if not db.sound or savedSound then return end
    savedSound = {GetCVar("Sound_EnableSFX"), GetCVar("Sound_SFXVolume")}
    SetCVar("Sound_EnableSFX", "1")
    SetCVar("Sound_SFXVolume", "1")
end

local function restoreSound()
    if not savedSound then return end
    SetCVar("Sound_EnableSFX", savedSound[1])
    SetCVar("Sound_SFXVolume", savedSound[2])
    savedSound = nil
end

local function isFishingSpell(...)
    local fishingName
    if C_Spell and C_Spell.GetSpellName then fishingName = C_Spell.GetSpellName(7620) end
    if not fishingName and GetSpellInfo then fishingName = GetSpellInfo(7620) end
    for i = 1, select("#", ...) do
        local arg = select(i, ...)
        if arg == 7620 or arg == fishingName then return true end
    end
    local channel = UnitChannelInfo("player")
    return channel and fishingName and channel == fishingName
end

local gatherSpells = {ore=2575, herb=2366, skinning=8613}
local function gatheringSpell(...)
    for mode, spellID in pairs(gatherSpells) do
        local spellName
        if C_Spell and C_Spell.GetSpellName then spellName = C_Spell.GetSpellName(spellID) end
        if not spellName and GetSpellInfo then spellName = GetSpellInfo(spellID) end
        for i = 1, select("#", ...) do
            local arg = select(i, ...)
            if arg == spellID or spellName and arg == spellName then return mode end
        end
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        if ... ~= addonName then return end
        GatherTogetherDB = GatherTogetherDB or FishNTipsDB or {}
        db = GatherTogetherDB
        db.positions = db.positions or {}
        db.positions.GatherTogetherGuide = db.positions.GatherTogetherGuide or db.positions.FishNTipsGuide
        db.positions.GatherTogetherMini = db.positions.GatherTogetherMini or db.positions.FishNTipsMini
        db.catches = db.catches or {}
        db.spots = db.spots or {}
        FishNTipsDB = nil
        if db.sound == nil then db.sound = true end
        if db.showMini == nil then db.showMini = false end
        makeMini()
        makeGuide()
        GatherTogetherMinimap.Create(db, function()
            if guide:IsShown() then guide:Hide() else guide:Show() end
        end)
        if db.showMini then mini:Show() end
        updateMini()
        SLASH_GATHERTOGETHER1 = "/gt"
        SLASH_GATHERTOGETHER2 = "/gathertogether"
        SlashCmdList.GATHERTOGETHER = function(input)
            input = normalize(input)
            if input == "mini" then
                db.showMini = not mini:IsShown()
                if db.showMini then updateMini(); mini:Show() else mini:Hide() end
            elseif input == "son" or input == "sound" then
                db.sound = not db.sound
                if not db.sound then restoreSound() elseif casting then boostSound() end
                say(L(db.sound and "SOUND_ON" or "SOUND_OFF"))
            elseif input == "aide" or input == "help" then
                say(L("HELP"))
            else
                if guide:IsShown() then guide:Hide() else updateGuide(); guide:Show() end
            end
        end
        events:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
        events:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
        pcall(events.RegisterEvent, events, "UNIT_SPELLCAST_START")
        pcall(events.RegisterEvent, events, "UNIT_SPELLCAST_STOP")
        pcall(events.RegisterEvent, events, "UNIT_SPELLCAST_SUCCEEDED")
        pcall(events.RegisterEvent, events, "UNIT_SPELLCAST_FAILED")
        pcall(events.RegisterEvent, events, "UNIT_SPELLCAST_INTERRUPTED")
        events:RegisterEvent("LOOT_OPENED")
        events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        events:RegisterEvent("ZONE_CHANGED")
        pcall(events.RegisterEvent, events, "SKILL_LINES_CHANGED")
        pcall(events.RegisterEvent, events, "PLAYER_EQUIPMENT_CHANGED")
        pcall(events.RegisterEvent, events, "UNIT_INVENTORY_CHANGED")
        pcall(events.RegisterEvent, events, "UNIT_AURA")
        pcall(events.RegisterEvent, events, "GET_ITEM_INFO_RECEIVED")
        events:RegisterEvent("PLAYER_LOGOUT")
        events:RegisterEvent("PLAYER_ENTERING_WORLD")
        return
    end
    if event == "PLAYER_ENTERING_WORLD" then
        GatherTogetherMinimap.Create(db, function()
            if guide:IsShown() then guide:Hide() else guide:Show() end
        end)
        return
    end
    if event == "PLAYER_LOGOUT" then restoreSound(); return end
    if event == "UNIT_SPELLCAST_START" then
        local unit = ...
        local mode = unit == "player" and gatheringSpell(...) or nil
        if mode and db.mode == mode then
            gatheringMode = mode
            updateMini()
            mini:Show()
        end
        return
    end
    if event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_SUCCEEDED"
        or event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
        if ... == "player" and gatheringMode then
            gatheringMode = nil
            if not db.showMini then
                C_Timer.After(6, function() if not gatheringMode and not casting and not db.showMini then mini:Hide() end end)
            end
        end
        return
    end
    if event == "UNIT_SPELLCAST_CHANNEL_START" then
        local unit = ...
        if unit ~= "player" or not isFishingSpell(...) then return end
        casting = true
        lastCastAt = GetTime()
        local zone, location = currentLocation()
        lastLocation = location
        lastZoneKey = zone and zone.en or normalize(location)
        lastPosition = zone and playerMapPosition(zone.mapID) or nil
        boostSound()
        mini:Show()
        updateMini()
        return
    end
    if event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        local unit = ...
        if unit ~= "player" or not casting then return end
        casting = false
        lastCastAt = GetTime()
        restoreSound()
        updateMini()
        if not db.showMini then C_Timer.After(8, function() if not casting and not db.showMini then mini:Hide() end end) end
        return
    end
    if event == "LOOT_OPENED" then
        if not lastCastAt or (not casting and GetTime() - lastCastAt > 5) then return end
        local location = lastLocation or select(2, currentLocation())
        if not location or location == "" then return end
        local key = lastZoneKey or normalize(location)
        local bucket = db.catches[key] or {}
        db.catches[key] = bucket
        for i = 1, (GetNumLootItems and GetNumLootItems() or 0) do
            local link = GetLootSlotLink and GetLootSlotLink(i)
            local id = link and tonumber(link:match("item:(%d+)"))
            if id then
                bucket[id] = (bucket[id] or 0) + 1
                rememberFishingArea(zoneByEnglish[lastZoneKey], lastPosition, id)
            end
        end
        lastCastAt = nil
        lastPosition = nil
        updateMini()
        if guide:IsShown() then updateGuide() end
        return
    end
    if event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" or event == "SKILL_LINES_CHANGED"
        or event == "PLAYER_EQUIPMENT_CHANGED" or event == "GET_ITEM_INFO_RECEIVED"
        or (event == "UNIT_INVENTORY_CHANGED" and ... == "player")
        or (event == "UNIT_AURA" and ... == "player") then
        updateMini()
        if guide:IsShown() then updateGuide() end
    end
end)
