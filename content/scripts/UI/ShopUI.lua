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

local UIButton = require("UI.elements.UIButton")
local UICard = require("UI.elements.UICard")

function ShopUI:init(font, layout)
    self.font = font
    self.layout = layout
    self.active = false
    self.reward = 0
    -- Hover state
    self.hoveredIndex = -1

    self.cards = {}

    -- Register Layout Regions
    self.layout:register("Shop_Title", { anchor = "top-center", width = 100, height = 40, offsetX = 0, offsetY = 40 })
    self.layout:register("Shop_Gold", { anchor = "top-center", width = 100, height = 30, offsetX = 0, offsetY = 90 })
    self.layout:register("Shop_Reroll", { anchor = "bottom-left", width = 200, height = 60, offsetX = 50, offsetY = 40 })
    self.layout:register("Shop_Next", { anchor = "bottom-right", width = 200, height = 60, offsetX = 30, offsetY = 40 })

    -- Initialize Buttons
    self.nextButton = UIButton("Shop_Next", "Next Round >", self.font, function()
        self.shouldClose = true
    end)
    -- Custom colors for Next button
    self.nextButton.bgColor = { r = 0.8, g = 0.2, b = 0.2, a = 1 }
    self.nextButton.hoverColor = { r = 0.9, g = 0.3, b = 0.3, a = 1 }

    self.rerollButton = UIButton("Shop_Reroll", "Reroll", self.font, function()
        Shop:reroll()
        self:rebuildCards()
    end)
    self.rerollButton.bgColor = { r = 0.3, g = 0.3, b = 0.8, a = 1 }
    self.rerollButton.hoverColor = { r = 0.4, g = 0.4, b = 0.9, a = 1 }
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
        self.Metadata[id] = { name = data.name or id, desc = data.description or "No description" }
    else
        -- Fallback for enhancements not yet in JSON or missing files
        self.Metadata[id] = { name = id, desc = "Effect not defined" }
    end

    return self.Metadata[id]
end

function ShopUI:rebuildCards()
    self.cards = {}
    for i, joker in ipairs(Shop.jokers) do
        local meta = self:getMetadata(joker.id)

        -- Combine runtime data with metadata
        local cardData = {
            id = joker.id,
            name = meta.name,
            desc = meta.desc,
            price = joker.price,
            rarity = joker.rarity
        }

        local card = UICard(nil, cardData, self.font, function()
            local result, msg = Shop:buyJoker(i)
            if type(result) == "table" then
                if result.action == "select_card" or result.action == "select_card_for_imprint" then
                    self.pendingAction = result
                end
            end
            -- Rebuild after attempted buy (list might change)
            self:rebuildCards()
        end)

        table.insert(self.cards, card)
    end
end

function ShopUI:open(reward)
    self.active = true
    self.shouldClose = false
    self.pendingAction = nil
    self.reward = reward
    -- Initial generation
    Shop:generateJokers(CampaignState.currentAct or 1)
    self:rebuildCards()
end

function ShopUI:update(dt, mx, my, clicked)
    if not self.active then return false end
    if self.shouldClose then
        self.shouldClose = false
        return { action = "close" }
    end

    if self.pendingAction then
        local res = self.pendingAction
        self.pendingAction = nil
        return res
    end

    -- Check if card list needs sync (e.g. external modification)
    if #self.cards ~= #Shop.jokers then
        self:rebuildCards()
    end

    -- Layout Constants
    local winW, winH = graphics.getWindowSize()

    -- Update Buttons Position & State
    local nx, ny = self.layout:getPosition("Shop_Next")
    local nr = self.layout.regions["Shop_Next"]

    self.nextButton:setPos(nx, ny)
    self.nextButton:setSize(nr.width, nr.height)
    self.nextButton:update(dt, mx, my, clicked)

    local rx, ry = self.layout:getPosition("Shop_Reroll")
    local rr = self.layout.regions["Shop_Reroll"]

    self.rerollButton:setPos(rx, ry)
    self.rerollButton:setSize(rr.width, rr.height)
    self.rerollButton:update(dt, mx, my, clicked)

    -- Dynamic Card Layout
    local cardW = 220
    local cardH = 300
    local spacing = 240
    local numCards = #self.cards
    local contentWidth = math.max(0, (numCards - 1) * spacing + cardW)
    local startX = (winW - contentWidth) / 2
    local startY = math.max(150, (winH - cardH) / 2)

    -- Update Cards
    for i, card in ipairs(self.cards) do
        local x = startX + (i - 1) * spacing
        local y = startY
        card:setPos(x, y)
        -- Pass input to card
        card:update(dt, mx, my, clicked)
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

    -- Buttons
    self.nextButton:draw()
    self.rerollButton:draw()

    -- Render Cards
    for _, card in ipairs(self.cards) do
        card:draw()
    end
end

return ShopUI
