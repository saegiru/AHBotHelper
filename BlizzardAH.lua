-- AHBotHelper Blizzard Auction UI support
-- This module only fills Blizzard's native sell fields. Posting is handled by Core.lua/SlashCommands.lua.

AHBotHelper = AHBotHelper or {}
local AH = AHBotHelper

local function SetMoneyFields(prefix, copper)
    local g, s, c = AH:SplitMoney(copper)
    local gold = _G[prefix .. "Gold"]
    local silver = _G[prefix .. "Silver"]
    local copperBox = _G[prefix .. "Copper"]

    if gold then gold:SetText(g > 0 and g or "") end
    if silver then silver:SetText((g > 0 or s > 0) and s or "") end
    if copperBox then copperBox:SetText(c) end
end

function AH:FillBlizzardAuctionFields()
    if not self.db then self:InitializeDB() end
    if not self.db.autoFillBlizzard then return false end

    -- If these globals do not exist, the active AH UI is probably not Blizzard's native sell pane.
    if not StartPriceGold or not BuyoutPriceGold then return false end

    local prices = self:GetCurrentSellPrices()
    if not prices then return false end

    SetMoneyFields("StartPrice", prices.bid)
    SetMoneyFields("BuyoutPrice", prices.buyout)

    if AuctionsFrameAuctions_ValidatePage then
        AuctionsFrameAuctions_ValidatePage()
    end

    return true
end

local f = CreateFrame("Frame")
f:RegisterEvent("NEW_AUCTION_UPDATE")
f:SetScript("OnEvent", function(self)
    -- Wait out the client auto-fill routines.
    local delayTimer = 0
    self:SetScript("OnUpdate", function(this, elapsed)
        delayTimer = delayTimer + elapsed
        if delayTimer > 0.05 then
            this:SetScript("OnUpdate", nil)
            AH:FillBlizzardAuctionFields()
        end
    end)
end)
