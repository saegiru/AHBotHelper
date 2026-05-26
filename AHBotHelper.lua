-- Helper function to check if an item in the bag is Soulbound or a Quest Item
local function IsItemUnsellable(itemLink)
    local _, _, quality, _, _, itemClass = GetItemInfo(itemLink)
    if quality == 0 or quality == 6 or itemClass == "Quest" then
        return true
    end

    local scanner = CreateFrame("GameTooltip", "AHBotScannerTooltip", nil, "GameTooltipTemplate")
    scanner:SetOwner(WorldFrame, "ANCHOR_NONE")
    scanner:SetHyperlink(itemLink)

    for i = 1, scanner:NumLines() do
        local leftText = _G["AHBotScannerTooltipTextLeft" .. i]
        if leftText then
            local text = leftText:GetText()
            if text == ITEM_SOULBOUND or text == ITEM_BIND_ON_PICKUP or text == ITEM_CONJURED then
                return true
            end
        end
    end
    return false
end

-- Calculates the single-item target price based on worldserver.conf
local function GetAHBotTargetPrice(itemLink)
    if IsItemUnsellable(itemLink) then return nil end

    local _, _, quality, _, _, _, _, _, _, _, sellPrice = GetItemInfo(itemLink)
    if not sellPrice or sellPrice <= 0 then return nil end

    local basePrice = math.max(sellPrice, 1000)
    
    local qualityMult = 1.0
    if quality == 2 then qualityMult = 1.8
    elseif quality == 3 then qualityMult = 1.9
    elseif quality == 4 then qualityMult = 2.1
    elseif quality >= 5 then qualityMult = 3.0
    end

    local fineTune = 1.0
    local _, _, _, _, _, itemClass, itemSubClass = GetItemInfo(itemLink)

    if itemClass == "Armor" or itemClass == "Weapon" then
        if quality >= 2 then fineTune = 1.2 end
    end

    if itemClass == "Recipe" and quality == 4 then
        fineTune = 20.0
    end

    -- Base price * multipliers * 15% safety undercut buffer
    return (basePrice * qualityMult * fineTune) * 0.85
end

-- -------------------------------------------------------------------
-- NEW: AUCTION HOUSE AUTOMATION SECTION (Delayed Sync for 3.3.5a)
-- -------------------------------------------------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("NEW_AUCTION_UPDATE")

f:SetScript("OnEvent", function(self, event, ...)
    if AuctionFrame and AuctionFrame:IsVisible() then
        local name, texture, count, quality, canUse, price, pricePerItem, buyoutPrice, bidPrice = GetAuctionSellItemInfo()
        
        if name then
            local _, itemLink = GetItemInfo(name)
            if itemLink then
                local singleTargetPrice = GetAHBotTargetPrice(itemLink)
                
                if singleTargetPrice then
                    -- Calculate totals in copper
                    local totalBuyout = math.floor(singleTargetPrice * count)
                    local totalBid = math.floor(totalBuyout * 0.85)
                    
                    -- Break down bid copper
                    local bidG = math.floor(totalBid / 10000)
                    local bidS = math.floor((totalBid % 10000) / 100)
                    local bidC = math.floor(totalBid % 100)
                    
                    -- Break down buyout copper
                    local buyG = math.floor(totalBuyout / 10000)
                    local buyS = math.floor((totalBuyout % 10000) / 100)
                    local buyC = math.floor(totalBuyout % 100)
                    
                    -- Create a one-time frame update delay (approx 0.05 seconds)
                    -- This waits out the Blizzard client's auto-fill routines
                    local delayTimer = 0
                    self:SetScript("OnUpdate", function(this, elapsed)
                        delayTimer = delayTimer + elapsed
                        if delayTimer > 0.05 then
                            -- Clear the loop
                            this:SetScript("OnUpdate", nil)
                            
                            -- Inject values into the UI edit boxes
                            StartPriceGold:SetText(bidG > 0 and bidG or "")
                            StartPriceSilver:SetText((bidG > 0 or bidS > 0) and bidS or "")
                            StartPriceCopper:SetText(bidC)
                            
                            BuyoutPriceGold:SetText(buyG > 0 and buyG or "")
                            BuyoutPriceSilver:SetText((buyG > 0 or buyS > 0) and buyS or "")
                            BuyoutPriceCopper:SetText(buyC)
                            
                            -- Force the 3.3.5a UI to lock in the new pricing numbers
                            if AuctionsFrameAuctions_ValidatePage then
                                AuctionsFrameAuctions_ValidatePage()
                            end
                        end
                    end)
                end
            end
        end
    end
end)


-- TOOLTIP HOOK
-- -------------------------------------------------------------------
GameTooltip:HookScript("OnTooltipSetItem", function(self)
    local _, itemLink = self:GetItem()
    if itemLink then
        local targetPrice = GetAHBotTargetPrice(itemLink)
        if targetPrice then
            local gold = math.floor(targetPrice / 10000)
            local silver = math.floor((targetPrice % 10000) / 100)
            local copper = math.floor(targetPrice % 100)
            
            local goldIcon   = "|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t"
            local silverIcon = "|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t"
            local copperIcon = "|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t"
            
            local priceString = ""
            if gold > 0 then priceString = priceString .. gold .. goldIcon .. " " end
            if gold > 0 or silver > 0 then priceString = priceString .. silver .. silverIcon .. " " end
            priceString = priceString .. copper .. copperIcon

            self:AddLine(" ")
            self:AddLine("AHBot Buy Target (Per Item):", 1, 0.8, 0)
            self:AddLine(priceString, 1, 1, 1)
        end
    end
end)