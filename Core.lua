-- AHBotHelper Core
-- WoW 3.3.5a / Lua 5.1 compatible.

AHBotHelper = AHBotHelper or {}
local AH = AHBotHelper

local DEFAULTS = {
    enabled = true,
    autoFillBlizzard = true,
    tooltip = true,
    debug = false,

    -- Standalone companion pricing panel.
    showPricingPanel = true,
    panelLocked = false,

    -- Keep slightly below the computed AHBot buyer ceiling.
    safetyFactor = 0.85,

    -- Minimum base value in copper. The original addon used 1000 copper / 10 silver.
    minBaseCopper = 1000,

    -- Bid as a percentage of buyout.
    bidFactor = 0.85,

    -- Default auction duration. WoW 3.3.5 values are 1=12h, 2=24h, 3=48h.
    defaultDuration = 3,

    -- Quality multipliers. Index is item quality.
    qualityMultiplier = {
        [0] = 1.0, -- Poor; usually blocked by default.
        [1] = 1.0, -- Common
        [2] = 1.8, -- Uncommon
        [3] = 1.9, -- Rare
        [4] = 2.1, -- Epic
        [5] = 3.0, -- Legendary
        [6] = 3.0, -- Artifact; usually blocked by default.
        [7] = 3.0,
    },

    -- Extra tuning preserved from the original addon.
    gearFineTune = 1.2,
    epicRecipeFineTune = 20.0,

    -- Filter settings.
    skipPoor = true,
    skipArtifact = true,
    skipQuest = true,
    skipSoulbound = true,
    skipBoP = true,
    skipConjured = true,
}

local function CopyDefaults(src, dst)
    if type(dst) ~= "table" then dst = {} end
    for k, v in pairs(src) do
        if type(v) == "table" then
            dst[k] = CopyDefaults(v, dst[k])
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
    return dst
end

function AH:InitializeDB()
    AHBotHelperDB = CopyDefaults(DEFAULTS, AHBotHelperDB)
    self.db = AHBotHelperDB
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(_, _, addonName)
    if addonName == "AHBotHelper" then
        AH:InitializeDB()
    end
end)

function AH:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99AHBotHelper:|r " .. tostring(msg))
end

function AH:Debug(msg)
    if self.db and self.db.debug then
        self:Print("DEBUG: " .. tostring(msg))
    end
end

local scanner
local function GetScanner()
    if not scanner then
        scanner = CreateFrame("GameTooltip", "AHBotHelperScannerTooltip", nil, "GameTooltipTemplate")
        scanner:SetOwner(WorldFrame, "ANCHOR_NONE")
    end
    return scanner
end

function AH:IsItemUnsellable(itemLink)
    if not itemLink then return true end
    if not self.db then self:InitializeDB() end

    local _, _, quality, _, _, itemClass = GetItemInfo(itemLink)
    if not quality then return true end

    if self.db.skipPoor and quality == 0 then return true end
    if self.db.skipArtifact and quality == 6 then return true end
    if self.db.skipQuest and itemClass == "Quest" then return true end

    local tip = GetScanner()
    tip:ClearLines()
    tip:SetHyperlink(itemLink)

    for i = 1, tip:NumLines() do
        local leftText = _G["AHBotHelperScannerTooltipTextLeft" .. i]
        local text = leftText and leftText:GetText()
        if text then
            if self.db.skipSoulbound and text == ITEM_SOULBOUND then return true end
            if self.db.skipBoP and text == ITEM_BIND_ON_PICKUP then return true end
            if self.db.skipConjured and text == ITEM_CONJURED then return true end
        end
    end

    return false
end

function AH:GetTargetPrice(itemLink)
    if not self.db then self:InitializeDB() end
    if not self.db.enabled or self:IsItemUnsellable(itemLink) then return nil end

    local _, _, quality, _, _, itemClass, itemSubClass, _, _, _, sellPrice = GetItemInfo(itemLink)
    if not sellPrice or sellPrice <= 0 then return nil end

    local basePrice = math.max(sellPrice, self.db.minBaseCopper or 1000)
    local qualityMult = self.db.qualityMultiplier[quality] or 1.0
    local fineTune = 1.0

    if (itemClass == "Armor" or itemClass == "Weapon") and quality >= 2 then
        fineTune = fineTune * (self.db.gearFineTune or 1.2)
    end

    if itemClass == "Recipe" and quality == 4 then
        fineTune = fineTune * (self.db.epicRecipeFineTune or 20.0)
    end

    return math.floor(basePrice * qualityMult * fineTune * (self.db.safetyFactor or 0.85))
end

function AH:GetSellItemLink()
    local name = GetAuctionSellItemInfo and GetAuctionSellItemInfo()
    if not name then return nil end
    local _, itemLink = GetItemInfo(name)
    return itemLink
end

function AH:GetCurrentSellPrices()
    local name, _, count = GetAuctionSellItemInfo()
    if not name then return nil end

    local _, itemLink = GetItemInfo(name)
    if not itemLink then return nil end

    count = count or 1
    local singleTarget = self:GetTargetPrice(itemLink)
    if not singleTarget then return nil end

    local buyout = math.floor(singleTarget * count)
    local bid = math.floor(buyout * (self.db.bidFactor or 0.85))

    return {
        itemLink = itemLink,
        count = count,
        single = singleTarget,
        bid = bid,
        buyout = buyout,
    }
end

function AH:SplitMoney(copper)
    copper = math.floor(copper or 0)
    return math.floor(copper / 10000), math.floor((copper % 10000) / 100), copper % 100
end

function AH:FormatMoney(copper)
    local g, s, c = self:SplitMoney(copper)
    local out = ""
    if g > 0 then out = out .. g .. "g " end
    if g > 0 or s > 0 then out = out .. s .. "s " end
    return out .. c .. "c"
end

function AH:GetSelectedDuration()
    local duration
    if UIDropDownMenu_GetSelectedValue and DurationDropDown then
        duration = UIDropDownMenu_GetSelectedValue(DurationDropDown)
    end
    duration = duration or (self.db and self.db.defaultDuration) or 3
    return duration
end

function AH:PostCurrentSellItem()
    local prices = self:GetCurrentSellPrices()
    if not prices then
        self:Print("No sellable auction item found, or AHBot target price could not be calculated.")
        return false
    end

    StartAuction(prices.bid, prices.buyout, self:GetSelectedDuration())
    self:Print("Posted " .. prices.itemLink .. " x" .. prices.count .. " for " .. self:FormatMoney(prices.buyout) .. " buyout.")
    return true
end
