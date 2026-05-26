-- AHBotHelper ElvUI compatibility helpers
-- ElvUI may skin/replace auction controls, so this module avoids direct field names.
-- Use /ahbot post to post the current auction item through the game API.

AHBotHelper = AHBotHelper or {}
local AH = AHBotHelper

local button
local function CreatePostButton()
    if button then return end
    if not ElvUI and not _G.ElvUI then return end
    if not AuctionFrame then return end

    button = CreateFrame("Button", "AHBotHelperPostButton", AuctionFrame, "UIPanelButtonTemplate")
    button:SetWidth(130)
    button:SetHeight(22)
    button:SetText("AHBot Post")
    button:SetPoint("BOTTOMRIGHT", AuctionFrame, "BOTTOMRIGHT", -18, 14)
    button:SetScript("OnClick", function()
        AH:PostCurrentSellItem()
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("AHBotHelper")
        GameTooltip:AddLine("Posts the current sell item using the AHBot target bid/buyout.", 1, 1, 1)
        GameTooltip:AddLine("This works even when ElvUI does not expose Blizzard price boxes.", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("AUCTION_HOUSE_SHOW")
f:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED" and addonName ~= "ElvUI" and addonName ~= "AHBotHelper" then return end
    CreatePostButton()
end)
