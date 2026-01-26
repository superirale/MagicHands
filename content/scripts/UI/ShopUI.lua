-- ShopUI.lua
-- Visual shop interface

ShopUI = class()

-- Metadata cache (lazy loaded)
ShopUI.Metadata = {}

ShopUI.RarityColors = {
    common      = { r = 0.4, g = 0.6, b = 0.8, a = 1 }, -- Blueish
    uncommon    = { r = 0.2, g = 0.7, b = 0.4, a = 1 }, -- Greenish
    rare        = { r = 0.8, g = 0.3, b = 0.3, a = 1 }, -- Red
    legendary   = { r = 0.9, g = 0.8, b = 0.2, a = 1 }, -- Gold
    enhancement = { r = 0.5, g = 0.4, b = 0.8, a = 1 }, -- Purple
}

function ShopUI:init(font)
    self.font = font
    self.active = false
    self.reward = 0
    -- Hover state
    self.hoveredIndex = -1
    self.hoveredButton = nil -- "next", "reroll"
end

function ShopUI:getMetadata(id)
    if self.Metadata[id] then return self.Metadata[id] end

    -- Try Loading from JSON
    -- Helper to check file existence? loadJSON returns nil if failed.
    local path = "content/data/jokers/" .. id .. ".json"
    local data = nil

    if files and files.loadJSON then
        data = files.loadJSON(path)
    else
        print("Error: files.loadJSON not available")
    end

    if data then
        self.Metadata[id] = { name = data.name, desc = data.description }
    else
        -- Fallback for enhancements not yet in JSON or missing files
        self.Metadata[id] = { name = id, desc = "Effect not defined" }
    end

    return self.Metadata[id]
end

function ShopUI:open(reward)
    self.active = true
    self.reward = reward
    -- Initial generation
    Shop:generateJokers(CampaignState.currentAct or 1)
end

function ShopUI:update(dt, mx, my, clicked)
    if not self.active then return false end

    -- Layout Constants
    local startX = 290
    local cardW = 220
    local cardH = 300
    local spacing = 240
    local startY = 250

    self.hoveredIndex = -1
    self.hoveredButton = nil

    -- Check Jokers
    for i, joker in ipairs(Shop.jokers) do
        local x = startX + (i - 1) * spacing
        local y = startY

        if mx >= x and mx <= x + cardW and my >= y and my <= y + cardH then
            self.hoveredIndex = i
            if clicked then
                local result, msg = Shop:buyJoker(i)
                if type(result) == "table" and result.action == "select_card" then
                    return result
                end
            end
        end
    end

    -- Next Round Button (Bottom Right)
    if mx >= 1050 and mx <= 1250 and my >= 620 and my <= 680 then
        self.hoveredButton = "next"
        if clicked then
            return { action = "close" }
        end
    end

    -- Reroll Button (Bottom Left)
    if mx >= 50 and mx <= 250 and my >= 620 and my <= 680 then
        self.hoveredButton = "reroll"
        if clicked then
            Shop:reroll()
        end
    end

    return false
end

function ShopUI:draw()
    if not self.active then return end

    -- Background Overlay
    graphics.drawRect(0, 0, 1280, 720, { r = 0.05, g = 0.05, b = 0.08, a = 0.95 }, true)

    -- Header
    graphics.print(self.font, "SHOP", 600, 40, { r = 1, g = 1, b = 1, a = 1 })

    -- Gold Display
    local goldColor = { r = 1, g = 0.8, b = 0.2, a = 1 }
    graphics.print(self.font, "Gold: " .. Economy.gold, 600, 90, goldColor)

    -- Reroll info
    graphics.print(self.font, "Reroll: " .. Shop.shopRerollCost .. "g", 100, 590, { r = 0.7, g = 0.7, b = 0.7 })

    -- Render Jokers
    local startX = 290
    local cardW = 220
    local cardH = 300
    local spacing = 240
    local startY = 250

    for i, joker in ipairs(Shop.jokers) do
        local x = startX + (i - 1) * spacing
        local y = startY
        local meta = self:getMetadata(joker.id)
        local rarityColor = self.RarityColors[joker.rarity] or { r = 0.5, g = 0.5, b = 0.5, a = 1 }

        -- Card Body (Base)
        local baseColor = { r = 0.15, g = 0.15, b = 0.18, a = 1 }
        if self.hoveredIndex == i then
            baseColor = { r = 0.2, g = 0.2, b = 0.23, a = 1 }
            -- Highlight Border
            graphics.drawRect(x - 2, y - 2, cardW + 4, cardH + 4, rarityColor, true)
        end
        graphics.drawRect(x, y, cardW, cardH, baseColor, true)

        -- Header (Rarity Color)
        graphics.drawRect(x, y, cardW, 50, rarityColor, true)

        -- Name (White, Shadowed)
        graphics.print(self.font, meta.name, x + 10, y + 10, { r = 0, g = 0, b = 0, a = 0.5 }) -- Shadow
        graphics.print(self.font, meta.name, x + 9, y + 9, { r = 1, g = 1, b = 1, a = 1 })

        -- Description (Wrapped manually logic or just split lines known)
        -- Assuming primitive print, manually spacing
        graphics.print(self.font, meta.desc, x + 10, y + 70, { r = 0.9, g = 0.9, b = 0.9, a = 1 })

        -- Price Tag
        local priceY = y + cardH - 40
        graphics.drawRect(x, priceY, cardW, 40, { r = 0, g = 0, b = 0, a = 0.3 }, true)
        local priceColor = { r = 1, g = 0.8, b = 0.2, a = 1 }
        if Economy.gold < joker.price then priceColor = { r = 0.8, g = 0.2, b = 0.2, a = 1 } end
        graphics.print(self.font, joker.price .. "g", x + 15, priceY + 8, priceColor)

        -- Buy Label
        if self.hoveredIndex == i then
            graphics.print(self.font, "BUY", x + 150, priceY + 8, { r = 0.4, g = 1, b = 0.4 })
        end
    end

    -- Next Round Button
    local nextColor = { r = 0.8, g = 0.2, b = 0.2, a = 1 }
    if self.hoveredButton == "next" then nextColor = { r = 0.9, g = 0.3, b = 0.3, a = 1 } end
    graphics.drawRect(1050, 620, 200, 60, nextColor, true)
    graphics.print(self.font, "Next Round >", 1080, 635)

    -- Reroll Button
    local rerollColor = { r = 0.3, g = 0.3, b = 0.8, a = 1 }
    if self.hoveredButton == "reroll" then rerollColor = { r = 0.4, g = 0.4, b = 0.9, a = 1 } end
    graphics.drawRect(50, 620, 200, 60, rerollColor, true)
    graphics.print(self.font, "Reroll", 100, 635)
end

return ShopUI
