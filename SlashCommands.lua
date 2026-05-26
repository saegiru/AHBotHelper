-- AHBotHelper slash commands

AHBotHelper = AHBotHelper or {}
local AH = AHBotHelper

SLASH_AHBOTHELPER1 = "/ahbot"
SLASH_AHBOTHELPER2 = "/ahbothelper"

SlashCmdList["AHBOTHELPER"] = function(msg)
    if not AH.db then AH:InitializeDB() end
    msg = string.lower(msg or "")
    local cmd, a, b = string.match(msg, "^(%S*)%s*(%S*)%s*(%S*)")

    if cmd == "post" then AH:PostCurrentSellItem(); return end
    if cmd == "panel" then AH:ShowPricingPanel(); return end
    if cmd == "fill" then if AH:FillBlizzardAuctionFields() then AH:Print("Filled Blizzard auction fields.") else AH:Print("Could not fill fields.") end; return end
    if cmd == "price" then local p=AH:GetCurrentSellPrices(); if p then AH:Print(p.itemLink.." x"..p.count..": "..AH:FormatMoney(p.single).." each, "..AH:FormatMoney(p.buyout).." stack buyout.") else AH:Print("No sellable auction item found, or AHBot target price could not be calculated.") end; return end
    if cmd == "debug" then AH.db.debug = not AH.db.debug; AH:Print("Debug is now " .. (AH.db.debug and "ON" or "OFF") .. "."); return end
    if cmd == "config" or cmd == "show" then AH:ShowConfig(); return end
    if cmd == "help" or cmd == "" then AH:Print("Commands: price, panel, fill, post, config, reset, help"); AH:PrintConfigHelp(); return end
    if cmd == "reset" then AH:ResetDB(); AH:Print("Config reset to defaults."); return end

    if cmd == "safety" then AH:SetNumberSetting("safetyFactor", a, 0, 10); return end
    if cmd == "bid" then AH:SetNumberSetting("bidFactor", a, 0, 1); return end
    if cmd == "minbase" then AH:SetNumberSetting("minBaseCopper", a, 0, 100000000); return end
    if cmd == "duration" then AH:SetNumberSetting("defaultDuration", a, 1, 3); return end
    if cmd == "gear" then AH:SetNumberSetting("gearFineTune", a, 0, 100); return end
    if cmd == "epicrecipe" then AH:SetNumberSetting("epicRecipeFineTune", a, 0, 100); return end
    if cmd == "quality" then AH:SetQualityMultiplier(a, b); return end

    if cmd == "enabled" then AH:SetBoolSetting("enabled", a); return end
    if cmd == "tooltip" then AH:SetBoolSetting("tooltip", a); return end
    if cmd == "autofill" then AH:SetBoolSetting("autoFillBlizzard", a); return end
    if cmd == "showpanel" then AH:SetBoolSetting("showPricingPanel", a); if AH.db.showPricingPanel then AH:ShowPricingPanel() else AH:HidePricingPanel() end; return end
    if cmd == "lockpanel" then AH:SetBoolSetting("panelLocked", a); return end
    if cmd == "skippoor" then AH:SetBoolSetting("skipPoor", a); return end
    if cmd == "skipquest" then AH:SetBoolSetting("skipQuest", a); return end
    if cmd == "skipsoulbound" then AH:SetBoolSetting("skipSoulbound", a); return end
    if cmd == "skipbop" then AH:SetBoolSetting("skipBoP", a); return end
    if cmd == "skipconjured" then AH:SetBoolSetting("skipConjured", a); return end

    AH:Print("Unknown command. Use /ahbot help.")
end
