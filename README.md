# AHBotHelper Refactor

This is a refactored WoW 3.3.5a addon for pricing auctions so AzerothCore `mod-ah-bot` is more likely to buy posted items.

## What changed

- Split one large Lua file into smaller modules:
  - `Core.lua` - pricing logic, saved settings, reusable API
  - `Tooltip.lua` - item tooltip target price display
  - `PricingPanel.lua` - standalone companion panel with AHBot prices and posting buttons
  - `BlizzardAH.lua` - native Blizzard Auction House field autofill
  - `ElvUICompat.lua` - ElvUI-friendly AHBot Post button helper
  - `SlashCommands.lua` - `/ahbot` commands
- Removed the hard dependency on `AuctionFrame:IsVisible()` for pricing.
- Reused one hidden tooltip scanner instead of creating a new tooltip every scan.
- Added a reusable global API:
  - `AHBotHelper:GetTargetPrice(itemLink)`
  - `AHBotHelper:GetCurrentSellPrices()`
  - `AHBotHelper:PostCurrentSellItem()`
- Added `/ahbot post`, which uses `StartAuction(bid, buyout, duration)` instead of relying only on visible UI edit boxes.

## Commands

```text
/ahbot price   Shows calculated price for the current auction sell item.
/ahbot panel   Opens the standalone AHBotHelper pricing panel.
/ahbot fill    Fills Blizzard native auction price boxes.
/ahbot post    Posts the current auction sell item using AHBotHelper prices.
/ahbot debug   Toggles debug mode.
```

## ElvUI note

ElvUI often skins or replaces visible auction controls. Because of that, writing directly to Blizzard globals like `StartPriceGold` and `BuyoutPriceGold` may not affect what ElvUI displays.

The most reliable workaround is `/ahbot post` or the `AHBot Post` button, because those call WoW's auction posting API directly after calculating bid and buyout values.

## Tuning

Settings are stored in `AHBotHelperDB`. You can tune these defaults in `Core.lua` or by modifying the saved variables after first load:

- `safetyFactor` - default `0.85`
- `bidFactor` - default `0.85`
- `qualityMultiplier`
- `gearFineTune`
- `epicRecipeFineTune`
- item skip behavior for poor, artifact, quest, soulbound, BoP, and conjured items

## Manual config commands added in 0.3.0

```text
/ahbot config
/ahbot reset
/ahbot safety 0.85
/ahbot bid 0.85
/ahbot minbase 1000
/ahbot duration 3
/ahbot quality 3 1.9
/ahbot tooltip on
/ahbot autofill off
/ahbot showpanel on
/ahbot lockpanel on
/ahbot enabled on
```

These values are stored in `AHBotHelperDB` as SavedVariables, so they persist between sessions.


## Standalone pricing panel added in 0.4.0

The standalone panel is designed to work beside Blizzard's auction UI, ElvUI's auction interface, or another auction skin. It appears when an item is placed in the auction sell slot and shows:

- item link
- stack size
- AHBot target price per item
- stack bid
- stack buyout
- selected/default duration
- safety factor

Panel buttons:

```text
Refresh  Recalculates the displayed values.
Fill UI  Attempts to fill Blizzard's native auction price boxes.
Post     Posts through StartAuction() using AHBotHelper prices.
Lock     Prevents accidental dragging.
```

Relevant commands:

```text
/ahbot panel
/ahbot showpanel on|off
/ahbot lockpanel on|off
```
