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

function ShopUI:init(font, layout)
    self.font = font
    self.layout = layout
    self.active = false
    self.reward = 0
    -- Hover state
    self.hoveredIndex = -1
    self.hoveredButton = nil -- "next", "reroll"

    -- Register Layout Regions
    self.layout:register("Shop_Title", { anchor = "top-center", width = 100, height = 40, offsetX = 0, offsetY = 40 })
    self.layout:register("Shop_Gold", { anchor = "top-center", width = 100, height = 30, offsetX = 0, offsetY = 90 })
    self.layout:register("Shop_Reroll",
        { anchor = "bottom-left", width = 200, height = 60, offsetX = 50, offsetY = 40 })
    self.layout:register("Shop_Next",
        { anchor = "bottom-right", width = 200, height = 60, offsetX = 30, offsetY = 40 })
end

function ShopUI:getMetadata(id)
    if self.Metadata[id] then return self.Metadata[id] end

    -- Try Loading from JSON
    -- Determine correct path based on item ID pattern
    local path = "content/data/jokers/" .. id .. ".json"

    -- Known imprints (from Phase 2 content)
    local imprints = {
        gold_inlay = true,
        lucky_pips = true,
        steel_plating = true,
        mint = true,
        tax = true,
        investment = true,
        insurance = true,
        dividend = true,
        echo = true,
        cascade = true,
        fractal = true,
        resonance = true,
        spark = true,
        ripple = true,
        pulse = true,
        crown = true,
        underdog = true,
        clutch = true,
        opener = true,
        majority = true,
        minority = true,
        wildcard_imprint = true,
        suit_shifter = true,
        mimic = true,
        nullifier = true
    }

    if string.find(id, "planet_") then
        path = "content/data/enhancements/" .. id .. ".json"
    elseif string.find(id, "warp_") or id == "spectral_echo" or id == "spectral_ghost" or id == "spectral_void" then
        path = "content/data/warps/" .. id .. ".json"
    elseif string.find(id, "spectral_") then
        path = "content/data/spectrals/" .. id .. ".json"
    elseif imprints[id] then
        path = "content/data/imprints/" .. id .. ".json"
    end
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
    local winW, winH = graphics.getWindowSize()

    -- Dynamic Card Layout
    local cardW = 220
    local cardH = 300
    local spacing = 240
    local numCards = #Shop.jokers
    local totalWidth = (numCards * cardW) + ((numCards - 1) * (spacing - cardW)) -- Spacing includes gap?
    -- Logic: x = start + (i-1)*spacing.
    -- Max X = start + (n-1)*spacing. Right edge = Max X + cardW.
    -- Width = (n-1)*spacing + cardW.
    local contentWidth = math.max(0, (numCards - 1) * spacing + cardW)
    local startX = (winW - contentWidth) / 2
    local startY = (winH - cardH) / 2          -- Center vertically too? Or fixed Y? Original 250.
    startY = math.max(150, (winH - cardH) / 2) -- Center but keep space for title

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
                if type(result) == "table" then
                    if result.action == "select_card" or result.action == "select_card_for_imprint" then
                        return result
                    end
                end
            end
        end
    end

    -- Next Round Button
    local nx, ny = self.layout:getPosition("Shop_Next")
    local regionNext = self.layout.regions["Shop_Next"]
    if regionNext and mx >= nx and mx <= nx + regionNext.width and my >= ny and my <= ny + regionNext.height then
        self.hoveredButton = "next"
        if clicked then
            return { action = "close" }
        end
    end

    -- Reroll Button
    local rx, ry = self.layout:getPosition("Shop_Reroll")
    local regionReroll = self.layout.regions["Shop_Reroll"]
    if regionReroll and mx >= rx and mx <= rx + regionReroll.width and my >= ry and my <= ry + regionReroll.height then
        self.hoveredButton = "reroll"
        if clicked then
            Shop:reroll()
        end
    end

    return false
end

function ShopUI:draw()
    if not self.active then return end

    local winW, winH = graphics.getWindowSize()

    -- Background Overlay
    graphics.drawRect(0, 0, winW, winH, { r = 0.05, g = 0.05, b = 0.08, a = 0.95 }, true)

    -- Header
    local tx, ty = self.layout:getPosition("Shop_Title")
    graphics.print(self.font, "SHOP", tx, ty, { r = 1, g = 1, b = 1, a = 1 })

    -- Gold Display
    local gx, gy = self.layout:getPosition("Shop_Gold")
    local goldColor = { r = 1, g = 0.8, b = 0.2, a = 1 }
    graphics.print(self.font, "Gold: " .. Economy.gold, gx, gy, goldColor)

    -- Reroll info (Near Reroll Button)
    local rx, ry = self.layout:getPosition("Shop_Reroll")
    graphics.print(self.font, "Reroll: " .. Shop.shopRerollCost .. "g", rx + 50, ry - 30,
        { r = 0.7, g = 0.7, b = 0.7 })

    -- Render Jokers
    local cardW = 220
    local cardH = 300
    local spacing = 240
    local numCards = #Shop.jokers
    local contentWidth = math.max(0, (numCards - 1) * spacing + cardW)
    local startX = (winW - contentWidth) / 2
    local startY = math.max(150, (winH - cardH) / 2)

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

        -- Description
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
    local nx, ny = self.layout:getPosition("Shop_Next")
    local regionNext = self.layout.regions["Shop_Next"]
    local nextColor = { r = 0.8, g = 0.2, b = 0.2, a = 1 }
    if self.hoveredButton == "next" then nextColor = { r = 0.9, g = 0.3, b = 0.3, a = 1 } end
    -- regionNext.width/height is available
    graphics.drawRect(nx, ny, regionNext.width, regionNext.height, nextColor, true)
    graphics.print(self.font, "Next Round >", nx + 30, ny + 15)

    -- Reroll Button
    local regionReroll = self.layout.regions["Shop_Reroll"]
    local rerollColor = { r = 0.3, g = 0.3, b = 0.8, a = 1 }
    if self.hoveredButton == "reroll" then rerollColor = { r = 0.4, g = 0.4, b = 0.9, a = 1 } end
    graphics.drawRect(rx, ry, regionReroll.width, regionReroll.height, rerollColor, true)
    graphics.print(self.font, "Reroll", rx + 50, ry + 15)
end

return ShopUI
