-- AHBotHelper configuration helpers

AHBotHelper = AHBotHelper or {}
local AH = AHBotHelper

local function BoolText(v) return v and "ON" or "OFF" end

local function ParseBool(v)
    v = string.lower(tostring(v or ""))
    if v == "on" or v == "true" or v == "yes" or v == "1" then return true end
    if v == "off" or v == "false" or v == "no" or v == "0" then return false end
    return nil
end

function AH:ShowConfig()
    if not self.db then self:InitializeDB() end
    self:Print("Config: enabled=" .. BoolText(self.db.enabled) .. ", tooltip=" .. BoolText(self.db.tooltip) .. ", autofill=" .. BoolText(self.db.autoFillBlizzard) .. ", panel=" .. BoolText(self.db.showPricingPanel))
    self:Print("Pricing: safety=" .. self.db.safetyFactor .. ", bid=" .. self.db.bidFactor .. ", minbase=" .. self:FormatMoney(self.db.minBaseCopper) .. ", duration=" .. self.db.defaultDuration)
    self:Print("Fine tune: gear=" .. self.db.gearFineTune .. ", epicrecipe=" .. self.db.epicRecipeFineTune)
    self:Print("Quality: poor=" .. self.db.qualityMultiplier[0] .. ", common=" .. self.db.qualityMultiplier[1] .. ", uncommon=" .. self.db.qualityMultiplier[2] .. ", rare=" .. self.db.qualityMultiplier[3] .. ", epic=" .. self.db.qualityMultiplier[4])
end

function AH:SetNumberSetting(key, value, minValue, maxValue)
    if not self.db then self:InitializeDB() end
    local n = tonumber(value)
    if not n or n < minValue or n > maxValue then
        self:Print("Invalid value. Expected number between " .. minValue .. " and " .. maxValue .. ".")
        return
    end
    self.db[key] = n
    self:Print(key .. " set to " .. n .. ".")
end

function AH:SetBoolSetting(key, value)
    if not self.db then self:InitializeDB() end
    local b = ParseBool(value)
    if b == nil then
        self:Print("Invalid value. Use on/off.")
        return
    end
    self.db[key] = b
    self:Print(key .. " is now " .. BoolText(b) .. ".")
end

function AH:SetQualityMultiplier(q, value)
    if not self.db then self:InitializeDB() end
    q = tonumber(q); value = tonumber(value)
    if not q or q < 0 or q > 7 or not value or value < 0 or value > 100 then
        self:Print("Usage: /ahbot quality <0-7> <multiplier>")
        return
    end
    self.db.qualityMultiplier[q] = value
    self:Print("qualityMultiplier[" .. q .. "] set to " .. value .. ".")
end

function AH:PrintConfigHelp()
    self:Print("Config: /ahbot config, panel, reset, safety <n>, bid <n>, minbase <copper>, duration <1-3>")
    self:Print("Toggles: /ahbot enabled|tooltip|autofill|showpanel|lockpanel|skippoor|skipquest|skipsoulbound|skipbop|skipconjured on|off")
    self:Print("Tuning: /ahbot gear <n>, epicrecipe <n>, quality <0-7> <n>")
end
