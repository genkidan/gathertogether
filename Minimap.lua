GatherTogetherMinimap = {}
local ICON = "Interface\\AddOns\\GatherTogether\\Media\\GatherTogetherIcon"

function GatherTogetherMinimap.Create(db, toggle)
    if not Minimap then return nil end
    if GatherTogetherMinimap.button then return GatherTogetherMinimap.button end
    local button = CreateFrame("Button", "GatherTogetherMinimapButton", Minimap)
    GatherTogetherMinimap.button = button
    button:SetSize(32, 32)
    button:SetFrameStrata("HIGH")
    button:SetFrameLevel((Minimap:GetFrameLevel() or 1) + 5)
    button:RegisterForClicks("LeftButtonUp")
    button:RegisterForDrag("LeftButton")
    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetColorTexture(0.08, 0.08, 0.08, 1)
    background:SetPoint("TOPLEFT", 5, -5)
    background:SetPoint("BOTTOMRIGHT", -5, 5)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 5, -5)
    icon:SetPoint("BOTTOMRIGHT", -5, 5)
    icon:SetTexture(ICON)
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetColorTexture(1, 1, 1, 0.15)
    highlight:SetAllPoints(icon)
    local ring = button:CreateTexture(nil, "OVERLAY")
    ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    ring:SetSize(54, 54)
    ring:SetPoint("TOPLEFT", 0, 0)
    local function position(angle)
        angle = tonumber(angle) or 225
        local radius = (tonumber(Minimap:GetWidth()) or 140) / 2 + 5
        local radians = angle * math.pi / 180
        button:ClearAllPoints()
        button:SetPoint("CENTER", Minimap, "CENTER", math.cos(radians) * radius, math.sin(radians) * radius)
    end
    button:SetScript("OnClick", toggle)
    button:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local cx, cy = Minimap:GetCenter()
            if not cx or not cy then return end
            local x, y = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            x, y = x / scale - cx, y / scale - cy
            local angle
            if x == 0 then angle = y >= 0 and 90 or -90
            else angle = math.atan(y / x) * 180 / math.pi; if x < 0 then angle = angle + 180 end end
            db.minimapAngle = angle
            position(angle)
        end)
    end)
    button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    button:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Gather Together")
        GameTooltip:AddLine(GatherTogetherL("MINIMAP"), 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    position(db.minimapAngle)
    return button
end
