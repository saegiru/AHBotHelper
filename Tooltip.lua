-- AHBotHelper Tooltip integration

AHBotHelper = AHBotHelper or {}
local AH = AHBotHelper

local goldIcon = "|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t"
local silverIcon = "|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t"
local copperIcon = "|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t"

local function IconMoney(copper)
    local g, s, c = AH:SplitMoney(copper)
    local out = ""
    if g > 0 then out = out .. g .. goldIcon .. " " end
    if g > 0 or s > 0 then out = out .. s .. silverIcon .. " " end
    return out .. c .. copperIcon
end

GameTooltip:HookScript("OnTooltipSetItem", function(self)
    if AH.db and AH.db.tooltip == false then return end
    local _, itemLink = self:GetItem()
    if not itemLink then return end

    local targetPrice = AH:GetTargetPrice(itemLink)
    if not targetPrice then return end

    self:AddLine(" ")
    self:AddLine("AHBot Buy Target (Per Item):", 1, 0.8, 0)
    self:AddLine(IconMoney(targetPrice), 1, 1, 1)
end)
