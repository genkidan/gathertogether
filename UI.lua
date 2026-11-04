GatherTogetherUI = {}
local L = GatherTogetherL
local ICON = "Interface\\AddOns\\GatherTogether\\Media\\GatherTogetherIcon"
local AREA = "Interface\\AddOns\\GatherTogether\\Media\\FishingArea"
local WHITE = "Interface\\Buttons\\WHITE8X8"
local palette = {
    bg = {0.012, 0.020, 0.034, 0.98}, surface = {0.035, 0.055, 0.080, 0.98},
    card = {0.060, 0.080, 0.105, 0.96}, border = {0.42, 0.32, 0.16, 0.88},
    accent = {0.98, 0.73, 0.26, 1}, muted = {0.62, 0.68, 0.72, 1},
}

local function tint(frame, fill, border)
    frame:SetBackdrop({bgFile=WHITE, edgeFile=WHITE, edgeSize=1,
        insets={left=1,right=1,top=1,bottom=1}})
    frame:SetBackdropColor(fill[1], fill[2], fill[3], fill[4])
    border = border or palette.border
    frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4])
end

local function label(parent, font, color)
    local text = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    if color then text:SetTextColor(color[1], color[2], color[3], color[4]) end
    return text
end

local function makeCard(parent, x, y, width, height)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetPoint("TOPLEFT", x, y)
    card:SetSize(width, height)
    tint(card, palette.card)
    return card
end

local function clearTiles(frame)
    for _, tile in ipairs(frame.mapTiles) do tile:Hide() end
    for _, tile in ipairs(frame.mapOverlays) do tile:Hide() end
    for _, area in ipairs(frame.mapAreas) do area:Hide() end
end

local function renderAreas(frame, zone, api, drawW, drawH)
    local areas = api.areas(zone, frame.mode)
    local index = 0
    for _, entry in ipairs(areas) do
        local matches = not frame.areaFilter
        if not matches then
            for _, id in ipairs(entry.fish or {}) do
                if id == frame.areaFilter then matches = true; break end
            end
        end
        if matches then
            index = index + 1
            local button = frame.mapAreas[index]
            if not button then
                button = CreateFrame("Button", nil, frame.mapCanvas)
                button.glow = button:CreateTexture(nil, "OVERLAY")
                button.glow:SetAllPoints()
                button.glow:SetTexture(AREA)
                button:SetScript("OnEnter", function(self)
                    if not GameTooltip then return end
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText(frame.mode == "fishing" and L("FISHING_AREA") or
                        frame.mode == "cloth" and L("CLOTH_AREA") or L("GATHERING"))
                    local source = self.area.learned and "AREA_OBSERVED" or self.area.reported and "AREA_REPORTED" or "AREA_ESTIMATE"
                    GameTooltip:AddLine(frame.mode == "fishing" and L(source) or
                        frame.mode == "cloth" and L("CLOTH_MAP_SOURCE") or L("GATHERING"),
                        0.65, 0.75, 0.85, true)
                    for _, id in ipairs(self.area.fish or {}) do
                        GameTooltip:AddLine(api.itemName(id, frame.mode), 1, 0.85, 0.5)
                    end
                    GameTooltip:Show()
                end)
                button:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
                frame.mapAreas[index] = button
            end
            button.area = entry
            button:ClearAllPoints()
            button:SetPoint("CENTER", frame.mapCanvas, "TOPLEFT", entry.x * drawW, -entry.y * drawH)
            button:SetSize(math.max(35, entry.rx * drawW * 2), math.max(35, entry.ry * drawH * 2))
            button:Show()
        end
    end
    frame.mapHint:SetText(index > 0 and
        (frame.mode == "fishing" and L("AREA_COUNT", index) or
            frame.mode == "cloth" and L("CLOTH_AREA_COUNT", index) or L("GATHERING") .. ": " .. index) or
        (frame.mode == "skinning" and L("NO_COORDS") or
            frame.mode == "cloth" and L("CLOTH_NO_AREA") or L("AREA_NONE")))
end

local function fileSize(pixels)
    local size = 16
    while size < pixels do size = size * 2 end
    return size
end

local function drawOverlay(frame, key, files, layerW, layerH, tileW, tileH, drawW, drawH)
    local width, height, offsetX, offsetY = key:match("^(%d+):(%d+):(%-?%d+):(%-?%d+)$")
    width, height, offsetX, offsetY = tonumber(width), tonumber(height), tonumber(offsetX), tonumber(offsetY)
    if not (width and height and offsetX and offsetY) or width <= 0 or height <= 0 then return end
    local ids = {}
    for id in files:gmatch("%d+") do ids[#ids + 1] = tonumber(id) end
    local columns, rows = math.ceil(width / tileW), math.ceil(height / tileH)
    for row = 0, rows - 1 do
        for column = 0, columns - 1 do
            local id = ids[row * columns + column + 1]
            if id then
                local pixelW = math.min(tileW, width - column * tileW)
                local pixelH = math.min(tileH, height - row * tileH)
                local index = frame.mapOverlayCount + 1
                local tile = frame.mapOverlays[index]
                if not tile then
                    tile = frame.mapCanvas:CreateTexture(nil, "OVERLAY")
                    frame.mapOverlays[index] = tile
                end
                frame.mapOverlayCount = index
                tile:ClearAllPoints()
                tile:SetPoint("TOPLEFT", frame.mapCanvas, "TOPLEFT",
                    (offsetX + column * tileW) * drawW / layerW,
                    -(offsetY + row * tileH) * drawH / layerH)
                tile:SetSize(pixelW * drawW / layerW, pixelH * drawH / layerH)
                tile:SetTexCoord(0, pixelW / fileSize(pixelW), 0, pixelH / fileSize(pixelH))
                tile:SetTexture(id)
                tile:Show()
            end
        end
    end
end

local function renderMap(frame, zone, name, api)
    clearTiles(frame)
    frame.mapOverlayCount = 0
    local parentName = zone.mapFrom and name(zone.mapFrom) or nil
    frame.mapTitle:SetText(parentName and L("REGIONAL", parentName) or L("MAP"))
    frame.mapMissing:Hide()
    frame.mapHint:SetText("")
    if not zone.mapID or not C_Map or not C_Map.GetMapArtLayers or not C_Map.GetMapArtLayerTextures then
        frame.mapMissing:SetText(L("MAP_MISSING")); frame.mapMissing:Show(); return
    end
    local okLayers, layers = pcall(C_Map.GetMapArtLayers, zone.mapID)
    local okTextures, textures = pcall(C_Map.GetMapArtLayerTextures, zone.mapID, 1)
    local layer = okLayers and type(layers) == "table" and layers[1]
    if not layer or not okTextures or type(textures) ~= "table" or #textures == 0 then
        frame.mapMissing:SetText(L("MAP_MISSING")); frame.mapMissing:Show(); return
    end
    local layerW = tonumber(layer.layerWidth) or 1002
    local layerH = tonumber(layer.layerHeight) or 668
    local tileW = tonumber(layer.tileWidth) or 256
    local tileH = tonumber(layer.tileHeight) or 256
    if layerW <= 0 or layerH <= 0 or tileW <= 0 or tileH <= 0 then return end
    local drawW = math.min(680, 400 * layerW / layerH)
    local drawH = math.min(400, drawW * layerH / layerW)
    local columns = math.max(1, math.ceil(layerW / tileW))
    frame.mapCanvas:SetSize(drawW, drawH)
    for i, textureID in ipairs(textures) do
        local tile = frame.mapTiles[i]
        if not tile then
            tile = frame.mapCanvas:CreateTexture(nil, "ARTWORK")
            frame.mapTiles[i] = tile
        end
        local column, row = (i-1) % columns, math.floor((i-1) / columns)
        tile:ClearAllPoints()
        tile:SetPoint("TOPLEFT", frame.mapCanvas, "TOPLEFT", column * tileW * drawW / layerW, -row * tileH * drawH / layerH)
        tile:SetSize(tileW * drawW / layerW, tileH * drawH / layerH)
        tile:SetTexCoord(0, 1, 0, 1)
        tile:SetTexture(textureID)
        tile:Show()
    end
    -- The base art is the unexplored map. Draw the client's exploration art
    -- for every area so this preview does not depend on this character's travel.
    local okArt, artID = false, nil
    if C_Map.GetMapArtID then okArt, artID = pcall(C_Map.GetMapArtID, zone.mapID) end
    if not okArt then artID = nil end
    local overlays = artID and GatherTogetherMapOverlays and GatherTogetherMapOverlays[artID]
    if overlays then
        for key, files in pairs(overlays) do
            drawOverlay(frame, key, files, layerW, layerH, tileW, tileH, drawW, drawH)
        end
    end
    -- Include client-known overlays for maps introduced after the bundled data.
    if C_MapExplorationInfo and C_MapExplorationInfo.GetExploredMapTextures then
        local ok, explored = pcall(C_MapExplorationInfo.GetExploredMapTextures, zone.mapID)
        if ok and type(explored) == "table" then
            for _, info in ipairs(explored) do
                if type(info.textureWidth) == "number" and type(info.textureHeight) == "number"
                    and type(info.offsetX) == "number" and type(info.offsetY) == "number"
                    and type(info.fileDataIDs) == "table" then
                    local key = table.concat({info.textureWidth, info.textureHeight, info.offsetX, info.offsetY}, ":")
                    if not (overlays and overlays[key]) then
                        local ids = {}
                        for _, id in ipairs(info.fileDataIDs) do ids[#ids + 1] = tostring(id) end
                        drawOverlay(frame, key, table.concat(ids, ","), layerW, layerH, tileW, tileH, drawW, drawH)
                    end
                end
            end
        end
    end
    renderAreas(frame, zone, api, drawW, drawH)
end

local function makeFishRow(parent, frame)
    local row = CreateFrame("Button", nil, parent, "BackdropTemplate")
    row:SetSize(333, 58)
    tint(row, palette.surface, {0.19,0.26,0.32,0.8})
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(28, 28)
    row.icon:SetPoint("TOPLEFT", 5, -6)
    row.text = label(row, "GameFontHighlightSmall")
    row.text:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 8, -1)
    row.text:SetPoint("RIGHT", -42, 0)
    row.condition = label(row, "GameFontDisableSmall", palette.muted)
    row.condition:SetPoint("TOPLEFT", row.text, "BOTTOMLEFT", 0, -3)
    row.condition:SetPoint("RIGHT", -7, 0)
    row.count = label(row, "GameFontNormalSmall", palette.accent)
    row.count:SetPoint("TOPRIGHT", -8, -9)
    row.count:SetJustifyH("RIGHT")
    row:SetScript("OnEnter", function(self)
        if self.itemID and GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local ok = GameTooltip.SetHyperlink and pcall(GameTooltip.SetHyperlink, GameTooltip, "item:" .. self.itemID)
            if not ok then GameTooltip:SetText(self.text:GetText() or "") end
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    row:SetScript("OnClick", function(self)
        if not self.areaID or frame.mode == "skinning" then return end
        if frame.areaFilter == self.areaID then
            frame.areaFilter = nil
        else
            frame.areaFilter = self.areaID
        end
        frame:Refresh()
    end)
    return row
end

local function renderFish(frame, zone, api)
    local entries, parentFish = api.entries(zone, frame.mode)
    frame.fishTitle:SetText(frame.mode == "fishing" and (parentFish and L("FISH_PARENT") or L("FISH")) or
        frame.mode == "cloth" and L("CLOTH") or L("RESOURCES"))
    frame.fishEmpty:SetShown(#entries == 0)
    frame.fishEmpty:SetText(L(frame.mode == "fishing" and "FISH_MISSING" or "UNKNOWN"))
    local rows = frame.fishRows
    for i, entry in ipairs(entries) do
        local row = rows[i]
        if not row then row = makeFishRow(frame.fishContent, frame); rows[i] = row end
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", ((i-1) % 2) * 342, -math.floor((i-1)/2) * 64)
        row.itemID = entry.item or entry.id
        row.areaID = entry.id
        local active = frame.areaFilter == entry.id and frame.mode ~= "skinning"
        row:SetBackdropBorderColor(active and 0.98 or 0.19, active and 0.73 or 0.26,
            active and 0.26 or 0.32, active and 1 or 0.8)
        row.text:SetTextColor(active and 1 or 0.86, active and 0.79 or 0.89,
            active and 0.32 or 0.95)
        row.icon:SetTexture(api.icon(entry.item or entry.id))
        row.text:SetText(entry.name)
        row.condition:SetText(entry.condition or "")
        row.count:SetText(entry.count and entry.count > 0 and ("×" .. entry.count) or "")
        row:Show()
    end
    for i = #entries + 1, #rows do rows[i]:Hide() end
    frame.fishContent:SetHeight(math.max(1, math.ceil(#entries / 2) * 64))
end

function GatherTogetherUI.Create(db, zones, api)
    local frame = CreateFrame("Frame", "GatherTogetherGuide", UIParent, "BackdropTemplate")
    frame:SetSize(1040, 790)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    tint(frame, palette.bg)
    local pos = db.positions.GatherTogetherGuide
    if pos then frame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4]) else frame:SetPoint("CENTER") end
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint(1)
        db.positions.GatherTogetherGuide = {point, relativePoint, x, y}
    end)
    local top = frame:CreateTexture(nil, "BACKGROUND")
    top:SetColorTexture(0.035, 0.060, 0.093, 1)
    top:SetPoint("TOPLEFT", 1, -1)
    top:SetPoint("TOPRIGHT", -1, -1)
    top:SetHeight(60)
    local accent = frame:CreateTexture(nil, "BORDER")
    accent:SetColorTexture(0.72, 0.49, 0.17, 0.9)
    accent:SetPoint("TOPLEFT", 1, -60)
    accent:SetPoint("TOPRIGHT", -1, -60)
    accent:SetHeight(2)
    local brand = frame:CreateTexture(nil, "ARTWORK")
    brand:SetSize(44, 44)
    brand:SetPoint("TOPLEFT", 12, -8)
    brand:SetTexture(ICON)
    local title = label(frame, "GameFontNormalLarge", palette.accent)
    title:SetPoint("TOPLEFT", 66, -11)
    title:SetText("Gather Together")
    frame.skillTitle = label(frame, "GameFontNormalLarge", palette.accent)
    frame.skillTitle:SetPoint("TOPRIGHT", -42, -17)
    frame.skillTitle:SetJustifyH("RIGHT")
    local subtitle = label(frame, "GameFontHighlightSmall", palette.muted)
    subtitle:SetPoint("TOPLEFT", 67, -34)
    subtitle:SetText(L("LOCATIONS"))
    frame.subtitle = subtitle
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)
    local modes = {{"fishing", "SKILL"}, {"ore", "MINING"}, {"herb", "HERBALISM"},
        {"skinning", "SKINNING"}, {"cloth", "CLOTH"}}
    frame.mode = db.mode or "fishing"
    frame.modeButtons = {}
    for i, entry in ipairs(modes) do
        local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        button:SetSize(100, 25)
        button:SetPoint("TOPLEFT", 290 + (i - 1) * 104, -18)
        button:SetText(L(entry[2]))
        button:SetScript("OnClick", function() frame:SetMode(entry[1]) end)
        frame.modeButtons[entry[1]] = button
    end

    local sidebar = makeCard(frame, 12, -74, 275, 702)
    local sidebarTitle = label(sidebar, "GameFontNormal", palette.accent)
    sidebarTitle:SetPoint("TOPLEFT", 12, -12)
    sidebarTitle:SetText(L("LOCATIONS"))
    frame.sidebarTitle = sidebarTitle
    local current = CreateFrame("Button", nil, sidebar, "UIPanelButtonTemplate")
    current:SetSize(244, 25)
    current:SetPoint("TOPLEFT", 12, -38)
    current:SetText(L("CURRENT"))
    local searchLabel = label(sidebar, "GameFontNormalSmall", palette.muted)
    searchLabel:SetPoint("TOPLEFT", 14, -72)
    searchLabel:SetText(L("SEARCH_FISH"))
    frame.searchLabel = searchLabel
    local search = CreateFrame("EditBox", "GatherTogetherFishSearch", sidebar, "InputBoxTemplate")
    search:SetSize(242, 24)
    search:SetPoint("TOPLEFT", 14, -90)
    search:SetAutoFocus(false)
    frame.search = search
    local scroll = CreateFrame("ScrollFrame", "GatherTogetherZoneScroll", sidebar, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -124)
    scroll:SetPoint("BOTTOMRIGHT", -27, 10)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(235, 1)
    scroll:SetScrollChild(content)
    frame.zoneRows = {}
    local y = 0
    for _, zone in ipairs(zones) do
        local row = CreateFrame("Button", nil, content, "BackdropTemplate")
        row:SetSize(226, 32)
        row:SetPoint("TOPLEFT", 1, -y)
        tint(row, palette.surface, {0.15,0.20,0.26,0.7})
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        row.accent = row:CreateTexture(nil, "OVERLAY")
        row.accent:SetColorTexture(0.96, 0.69, 0.22, 1)
        row.accent:SetPoint("TOPLEFT", 0, 0)
        row.accent:SetPoint("BOTTOMLEFT", 0, 0)
        row.accent:SetWidth(3)
        row.name = label(row, "GameFontHighlightSmall")
        row.name:SetPoint("LEFT", 9, 0)
        row.name:SetPoint("RIGHT", -70, 0)
        row.name:SetJustifyV("MIDDLE")
        row.threshold = label(row, "GameFontNormalSmall", palette.muted)
        row.threshold:SetPoint("RIGHT", -7, 0)
        row.threshold:SetWidth(60)
        row.threshold:SetJustifyH("RIGHT")
        row:SetScript("OnClick", function()
            frame.selected = zone
            frame:Refresh()
        end)
        local entry = {frame=row, zone=zone}
        frame.zoneRows[#frame.zoneRows+1] = entry
        y = y + 36
    end
    content:SetHeight(y + 4)
    local noMatches = label(content, "GameFontHighlightSmall", palette.muted)
    noMatches:SetPoint("TOPLEFT", 3, -8)
    noMatches:SetText(L("NO_MATCH"))
    noMatches:Hide()
    function frame:FilterZones()
        local query = (strlower or string.lower)(self.search:GetText() or "")
        local matched = {}
        local count = 0
        for _, entry in ipairs(self.zoneRows) do
            local visible = (self.mode == "fishing" and not entry.zone.gatherOnly or
                self.mode ~= "fishing" and not entry.zone.mapFrom and api.has(entry.zone, self.mode))
                and (query == "" or api.matches(entry.zone, query, self.mode))
            matched[entry] = visible
            if visible then count = count + 1 end
        end
        local cursor = 0
        for _, entry in ipairs(self.zoneRows) do
            local visible = matched[entry]
            entry.frame:SetShown(visible)
            if visible then
                entry.frame:ClearAllPoints()
                entry.frame:SetPoint("TOPLEFT", content, "TOPLEFT", 1, -cursor)
                cursor = cursor + 36
            end
        end
        noMatches:SetShown(count == 0)
        content:SetHeight(math.max(32, cursor + 4))
        scroll:SetVerticalScroll(0)
    end
    search:SetScript("OnTextChanged", function() frame:FilterZones() end)
    search:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    search:SetScript("OnEscapePressed", function(self) self:SetText(""); self:ClearFocus(); frame:FilterZones() end)
    frame:FilterZones()

    local detail = makeCard(frame, 299, -74, 729, 702)
    frame.zoneTitle = label(detail, "GameFontNormalLarge", palette.accent)
    frame.zoneTitle:SetPoint("TOPLEFT", 14, -12)
    frame.zoneTitle:SetPoint("RIGHT", -10, 0)
    frame.zoneSubtitle = label(detail, "GameFontHighlightSmall", palette.muted)
    frame.zoneSubtitle:SetPoint("TOPLEFT", 15, -37)
    frame.zoneSubtitle:SetText(L("SOURCE"))
    local map = makeCard(detail, 12, -64, 705, 452)
    frame.mapTitle = label(map, "GameFontNormal", palette.accent)
    frame.mapTitle:SetPoint("TOPLEFT", 12, -9)
    frame.mapCanvas = CreateFrame("Frame", nil, map)
    frame.mapCanvas:SetPoint("CENTER", map, "CENTER", 0, -22)
    frame.mapCanvas:SetSize(680, 400)
    if frame.mapCanvas.SetClipsChildren then frame.mapCanvas:SetClipsChildren(true) end
    frame.mapTiles = {}
    frame.mapOverlays = {}
    frame.mapAreas = {}
    frame.mapHint = label(map, "GameFontDisableSmall", palette.muted)
    frame.mapHint:SetPoint("TOPRIGHT", -10, -27)
    frame.mapHint:SetJustifyH("RIGHT")
    frame.mapMissing = label(map, "GameFontHighlight", palette.muted)
    frame.mapMissing:SetPoint("CENTER", 0, -15)
    frame.mapMissing:SetJustifyH("CENTER")
    frame.fishTitle = label(detail, "GameFontNormal", palette.accent)
    frame.fishTitle:SetPoint("TOPLEFT", 14, -532)
    frame.fishScroll = CreateFrame("ScrollFrame", "GatherTogetherFishScroll", detail, "UIPanelScrollFrameTemplate")
    frame.fishScroll:SetPoint("TOPLEFT", 12, -558)
    frame.fishScroll:SetPoint("BOTTOMRIGHT", -30, 14)
    frame.fishContent = CreateFrame("Frame", nil, frame.fishScroll)
    frame.fishContent:SetSize(680, 1)
    frame.fishScroll:SetScrollChild(frame.fishContent)
    frame.fishRows = {}
    frame.fishEmpty = label(frame.fishContent, "GameFontHighlight", palette.muted)
    frame.fishEmpty:SetPoint("TOPLEFT", 7, -8)
    function frame:SetMode(mode)
        if mode ~= "fishing" and mode ~= "ore" and mode ~= "herb" and mode ~= "skinning"
            and mode ~= "cloth" then return end
        self.mode = mode
        self.areaFilter = nil
        db.mode = mode
        self.selected = nil
        self.search:SetText("")
        self:FilterZones()
        self:Refresh()
        if api.onMode then api.onMode() end
    end
    current:SetScript("OnClick", function() frame.selected = nil; frame:Refresh() end)

    function frame:Refresh()
        local zone = self.selected or api.current()
        if not zone or (self.mode ~= "fishing" and not api.has(zone, self.mode))
            or (self.mode == "fishing" and zone.gatherOnly) then
            for _, candidate in ipairs(zones) do
                if self.mode == "fishing" and not candidate.gatherOnly or
                    self.mode ~= "fishing" and not candidate.mapFrom and api.has(candidate, self.mode) then
                    zone = candidate; break
                end
            end
        end
        if self.areaFilterZone ~= zone then
            self.areaFilter = nil
            self.areaFilterZone = zone
        end
        self.zoneTitle:SetText(api.name(zone))
        for _, entry in ipairs(self.zoneRows) do
            local active = entry.zone == zone
            entry.frame.name:SetText(api.name(entry.zone))
            local minimum, maximum = api.zoneSkill(entry.zone, self.mode)
            local range = minimum and (minimum == maximum and tostring(minimum) or (minimum .. "–" .. maximum)) or ""
            entry.frame.threshold:SetText(range)
            entry.frame.name:SetTextColor(active and 1 or 0.86, active and 0.79 or 0.89, active and 0.32 or 0.95)
            entry.frame.accent:SetShown(active)
        end
        local skill, bonus = api.skill(self.mode)
        local skillName = self.mode == "fishing" and L("SKILL") or
            self.mode == "ore" and L("MINING") or self.mode == "herb" and L("HERBALISM") or L("SKINNING")
        self.skillTitle:SetText(self.mode == "cloth" and "" or
            (skill and L("BONUS_SKILL", skillName, skill, bonus or 0) or (skillName .. " ?")))
        self.zoneSubtitle:SetText(self.mode == "cloth" and L("CLOTH_MOON_NOTE") or L("SOURCE"))
        renderMap(self, zone, api.nameByEnglish, api)
        renderFish(self, zone, api)
        frame.searchLabel:SetText(self.mode == "fishing" and L("SEARCH_FISH") or
            self.mode == "cloth" and L("SEARCH_CLOTH") or L("SEARCH_RESOURCE"))
        frame.sidebarTitle:SetText(self.mode == "fishing" and L("LOCATIONS") or
            self.mode == "cloth" and L("CLOTH_LOCATIONS") or L("GATHERING"))
        frame.subtitle:SetText(self.mode == "fishing" and L("LOCATIONS") or
            self.mode == "cloth" and L("CLOTH_LOCATIONS") or L("GATHERING"))
        for mode, button in pairs(self.modeButtons) do button:SetAlpha(mode == self.mode and 1 or 0.68) end
    end
    frame:SetScript("OnShow", function(self) self:Refresh() end)
    frame:Hide()
    if UISpecialFrames then UISpecialFrames[#UISpecialFrames+1] = "GatherTogetherGuide" end
    return frame
end
