-- AHBotHelper standalone pricing panel
-- Companion panel that does not depend on Blizzard or ElvUI price edit boxes.

AHBotHelper = AHBotHelper or {}
local AH = AHBotHelper

local panel
local rows = {}

local function SetText(obj, value)
    if obj then obj:SetText(value or "") end
end

local function MakeFont(parent, name, size, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetJustifyH(justify or "LEFT")
    fs:SetText(name or "")
    return fs
end

local function AddRow(parent, index, label)
    local y = -48 - ((index - 1) * 20)
    local l = MakeFont(parent, nil, 12, "LEFT")
    l:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, y)
    l:SetWidth(110)
    l:SetText(label)

    local v = MakeFont(parent, nil, 12, "LEFT")
    v:SetPoint("LEFT", l, "RIGHT", 6, 0)
    v:SetWidth(210)
    v:SetTextColor(1, 1, 1)

    rows[label] = v
    return v
end

local function MakeButton(parent, name, text, width, onClick)
    local b = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
    b:SetWidth(width or 80)
    b:SetHeight(22)
    b:SetText(text)
    b:SetScript("OnClick", onClick)
    return b
end

function AH:CreatePricingPanel()
    if panel then return panel end

    panel = CreateFrame("Frame", "AHBotHelperPricingPanel", UIParent)
    panel:SetWidth(360)
    panel:SetHeight(230)
    panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    panel:SetFrameStrata("DIALOG")
    panel:EnableMouse(true)
    panel:SetMovable(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", function(self)
        if AH.db and AH.db.panelLocked then return end
        self:StartMoving()
    end)
    panel:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    local bg = panel:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(panel)
    bg:SetTexture(0, 0, 0, 0.82)

    local border = CreateFrame("Frame", nil, panel)
    border:SetPoint("TOPLEFT", panel, "TOPLEFT", 1, -1)
    border:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -1, 1)

    local title = MakeFont(panel, nil, 14, "LEFT")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -14)
    title:SetText("AHBotHelper Pricing")
    title:SetTextColor(0.2, 1, 0.6)

    local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -4, -4)

    AddRow(panel, 1, "Item:")
    AddRow(panel, 2, "Stack:")
    AddRow(panel, 3, "Per Item:")
    AddRow(panel, 4, "Stack Bid:")
    AddRow(panel, 5, "Stack Buyout:")
    AddRow(panel, 6, "Duration:")
    AddRow(panel, 7, "Safety:")

    local refresh = MakeButton(panel, "AHBotHelperRefreshButton", "Refresh", 75, function() AH:UpdatePricingPanel(true) end)
    refresh:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 14, 14)

    local fill = MakeButton(panel, "AHBotHelperFillButton", "Fill UI", 75, function()
        if AH:FillBlizzardAuctionFields() then
            AH:Print("Filled Blizzard auction fields.")
        else
            AH:Print("Could not fill Blizzard fields. Use Post instead, or check that the native sell pane is available.")
        end
        AH:UpdatePricingPanel(true)
    end)
    fill:SetPoint("LEFT", refresh, "RIGHT", 8, 0)

    local post = MakeButton(panel, "AHBotHelperPanelPostButton", "Post", 75, function()
        AH:PostCurrentSellItem()
        AH:UpdatePricingPanel(true)
    end)
    post:SetPoint("LEFT", fill, "RIGHT", 8, 0)

    local lock = MakeButton(panel, "AHBotHelperPanelLockButton", "Lock", 75, function(self)
        AH.db.panelLocked = not AH.db.panelLocked
        self:SetText(AH.db.panelLocked and "Unlock" or "Lock")
    end)
    lock:SetPoint("LEFT", post, "RIGHT", 8, 0)

    panel.lockButton = lock
    panel:Hide()
    return panel
end

local function DurationText(value)
    if value == 1 then return "12 hours" end
    if value == 2 then return "24 hours" end
    if value == 3 then return "48 hours" end
    return tostring(value or "Default")
end

function AH:UpdatePricingPanel(forceShow)
    if not self.db then self:InitializeDB() end
    if not self.db.showPricingPanel then return end

    local p = self:CreatePricingPanel()
    if p.lockButton then p.lockButton:SetText(self.db.panelLocked and "Unlock" or "Lock") end

    local prices = self:GetCurrentSellPrices()
    if not prices then
        SetText(rows["Item:"], "No auction sell item")
        SetText(rows["Stack:"], "-")
        SetText(rows["Per Item:"], "-")
        SetText(rows["Stack Bid:"], "-")
        SetText(rows["Stack Buyout:"], "-")
        SetText(rows["Duration:"], DurationText(self:GetSelectedDuration()))
        SetText(rows["Safety:"], tostring(self.db.safetyFactor or "-"))
        if forceShow then p:Show() end
        return
    end

    SetText(rows["Item:"], prices.itemLink)
    SetText(rows["Stack:"], tostring(prices.count))
    SetText(rows["Per Item:"], self:FormatMoney(prices.single))
    SetText(rows["Stack Bid:"], self:FormatMoney(prices.bid))
    SetText(rows["Stack Buyout:"], self:FormatMoney(prices.buyout))
    SetText(rows["Duration:"], DurationText(self:GetSelectedDuration()))
    SetText(rows["Safety:"], tostring(self.db.safetyFactor or "-"))

    p:Show()
end

function AH:ShowPricingPanel()
    self:UpdatePricingPanel(true)
end

function AH:HidePricingPanel()
    if panel then panel:Hide() end
end

local f = CreateFrame("Frame")
f:RegisterEvent("AUCTION_HOUSE_SHOW")
f:RegisterEvent("AUCTION_HOUSE_CLOSED")
f:RegisterEvent("NEW_AUCTION_UPDATE")
f:SetScript("OnEvent", function(self, event)
    if not AH.db then AH:InitializeDB() end
    if event == "AUCTION_HOUSE_CLOSED" then
        AH:HidePricingPanel()
        return
    end
    if event == "AUCTION_HOUSE_SHOW" then
        if AH.db.showPricingPanel then AH:CreatePricingPanel() end
        return
    end
    if event == "NEW_AUCTION_UPDATE" and AH.db.showPricingPanel then
        local delay = 0
        self:SetScript("OnUpdate", function(frame, elapsed)
            delay = delay + elapsed
            if delay > 0.05 then
                frame:SetScript("OnUpdate", nil)
                AH:UpdatePricingPanel(false)
            end
        end)
    end
end)
