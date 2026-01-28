ShopUI = class()

-- Metadata cache (lazy loaded)
ShopUI.Metadata = {}

-- Known imprint IDs (to avoid checking jokers directory for these)
-- This list is maintained by scanning content/data/imprints/
ShopUI.KnownImprints = {
    cascade = true,
    clutch = true,
    crown = true,
    dividend = true,
    echo = true,
    fractal = true,
    gold_inlay = true,
    insurance = true,
    investment = true,
    lucky_pips = true,
    majority = true,
    mimic = true,
    minority = true,
    mint = true,
    nullifier = true,
    opener = true,
    pulse = true,
    resonance = true,
    ripple = true,
    spark = true,
    steel_plating = true,
    suit_shifter = true,
    tax = true,
    underdog = true,
    wildcard_imprint = true
}

ShopUI.RarityColors = {
    common      = { r = 0.4, g = 0.6, b = 0.8, a = 1 }, -- Blueish
    uncommon    = { r = 0.2, g = 0.7, b = 0.4, a = 1 }, -- Greenish
    rare        = { r = 0.8, g = 0.3, b = 0.3, a = 1 }, -- Red
    legendary   = { r = 0.9, g = 0.8, b = 0.2, a = 1 }, -- Gold
    enhancement = { r = 0.5, g = 0.4, b = 0.8, a = 1 }, -- Purple
}

local UIButton = require("UI.elements.UIButton")
local UICard = require("UI.elements.UICard")
local UILabel = require("UI.elements.UILabel")

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
    self.layout:register("Shop_Reroll", { anchor = "bottom-left", width = 200, height = 60, offsetX = 0, offsetY = 0 })
    self.layout:register("Shop_SellJokers", { anchor = "bottom-left", width = 200, height = 60, offsetX = 220, offsetY = 0 })
    self.layout:register("Shop_Next", { anchor = "bottom-right", width = 200, height = 60, offsetX = 0, offsetY = 0 })

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
    
    self.sellButton = UIButton("Shop_SellJokers", "Sell Jokers", self.font, function()
        self.sellMode = not self.sellMode
        if self.sellMode then
            log.info("Sell mode enabled - click a joker to sell it")
        else
            log.info("Sell mode disabled")
        end
    end)
    self.sellButton.bgColor = { r = 0.6, g = 0.4, b = 0.1, a = 1 }
    self.sellButton.hoverColor = { r = 0.8, g = 0.5, b = 0.2, a = 1 }
    
    self.sellMode = false
    self.sellPrice = 25  -- Default sell price (half of typical buy price)
    self.jokerLabels = {}  -- UILabel instances for each joker slot
end

function ShopUI:updateJokerLabels()
    -- Create/update UILabel instances for joker slots
    self.jokerLabels = {}
    
    if not JokerManager or not JokerManager.slots then return end
    
    local winW, winH = graphics.getWindowSize()
    local jokerW = 120
    local jokerH = 40
    local jokerSpacing = 10
    local totalSlots = JokerManager.maxSlots
    local totalWidth = totalSlots * jokerW + (totalSlots - 1) * jokerSpacing
    local startX = (winW - totalWidth) / 2
    local startY = 140
    
    -- Create labels for filled slots
    for i, joker in ipairs(JokerManager.slots) do
        local x = startX + (i - 1) * (jokerW + jokerSpacing)
        local y = startY
        
        local jokerText = joker.id
        if joker.stack > 1 then
            jokerText = jokerText .. " x" .. joker.stack
        end
        
        local label = UILabel(nil, jokerText, self.font, { r = 1, g = 1, b = 1, a = 1 })
        label.x = x
        label.y = y
        label.width = jokerW
        label.height = jokerH
        label.align = "center"
        label.valign = "middle"
        label.lineSpacing = 14  -- Tighter line spacing for small slots
        
        table.insert(self.jokerLabels, {
            label = label,
            index = i,
            isEmpty = false
        })
    end
    
    -- Create labels for empty slots
    for i = #JokerManager.slots + 1, JokerManager.maxSlots do
        local x = startX + (i - 1) * (jokerW + jokerSpacing)
        local y = startY
        
        local label = UILabel(nil, "Empty", self.font, { r = 0.5, g = 0.5, b = 0.5, a = 1 })
        label.x = x
        label.y = y
        label.width = jokerW
        label.height = jokerH
        label.align = "center"
        label.valign = "middle"
        label.wrap = false  -- "Empty" doesn't need wrapping
        
        table.insert(self.jokerLabels, {
            label = label,
            index = i,
            isEmpty = true
        })
    end
end

function ShopUI:getMetadata(id)
    if self.Metadata[id] then return self.Metadata[id] end

    -- Try Loading from JSON
    -- Determine correct path based on item ID patterns
    local path = nil
    
    if string.find(id, "planet_") then
        path = "content/data/enhancements/" .. id .. ".json"
    elseif string.find(id, "warp_") or id == "spectral_echo" or id == "spectral_ghost" or id == "spectral_void" then
        path = "content/data/warps/" .. id .. ".json"
    elseif string.find(id, "spectral_") then
        path = "content/data/spectrals/" .. id .. ".json"
    elseif ShopUI.KnownImprints[id] then
        -- Check known imprints first to avoid unnecessary error logs
        path = "content/data/imprints/" .. id .. ".json"
    else
        -- Default to jokers directory
        path = "content/data/jokers/" .. id .. ".json"
    end
    
    local data = nil
    if files and files.loadJSON then
        data = files.loadJSON(path)
    else
        log.error("files.loadJSON not available")
    end

    if data then
        self.Metadata[id] = { name = data.name or id, desc = data.description or "No description" }
    else
        -- Fallback for items not yet in JSON or missing files
        log.warn("No metadata found for: " .. id .. " at path: " .. (path or "nil"))
        self.Metadata[id] = { name = id, desc = "Effect not defined" }
    end

    return self.Metadata[id]
end

function ShopUI:handleJokerSellClick(mx, my)
    if not JokerManager or not JokerManager.slots then return nil end
    
    -- Joker display area (centered at top of screen)
    local winW, winH = graphics.getWindowSize()
    local jokerW = 120
    local jokerH = 40
    local jokerSpacing = 10
    local totalSlots = JokerManager.maxSlots
    local totalWidth = totalSlots * jokerW + (totalSlots - 1) * jokerSpacing
    local startX = (winW - totalWidth) / 2
    local startY = 140
    
    for i, joker in ipairs(JokerManager.slots) do
        local x = startX + (i - 1) * (jokerW + jokerSpacing)
        local y = startY
        
        if mx >= x and mx <= x + jokerW and my >= y and my <= y + jokerH then
            -- Clicked on this joker - sell it
            local success, msg = JokerManager:sellJoker(i, self.sellPrice)
            if success then
                log.info("Sold joker: " .. msg .. " for " .. self.sellPrice .. "g")
            else
                log.warn("Failed to sell joker: " .. msg)
            end
            return { action = "joker_sold" }
        end
    end
    
    return nil
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
    self:updateJokerLabels()
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
    
    local sx, sy = self.layout:getPosition("Shop_SellJokers")
    local sr = self.layout.regions["Shop_SellJokers"]
    
    self.sellButton:setPos(sx, sy)
    self.sellButton:setSize(sr.width, sr.height)
    self.sellButton:update(dt, mx, my, clicked)
    
    -- Update sell button text based on mode
    if self.sellMode then
        self.sellButton.text = "Cancel Sell"
        self.sellButton.bgColor = { r = 0.8, g = 0.3, b = 0.1, a = 1 }
    else
        self.sellButton.text = "Sell Jokers"
        self.sellButton.bgColor = { r = 0.6, g = 0.4, b = 0.1, a = 1 }
    end
    
    -- Handle joker selling in sell mode
    if self.sellMode and clicked then
        -- Check if player clicked on their jokers (displayed at top)
        local jokerClickResult = self:handleJokerSellClick(mx, my)
        if jokerClickResult then
            self.sellMode = false
            return jokerClickResult
        end
    end

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

    -- Reroll cost (Above Reroll Button)
    local rx, ry = self.layout:getPosition("Shop_Reroll")
    local rr = self.layout.regions["Shop_Reroll"]
    local rerollText = "Cost: " .. Shop.shopRerollCost .. "g"
    local rerollTextW = graphics.getTextSize(self.font, rerollText)
    -- Center above the button
    local rerollTextX = rx + (rr.width - rerollTextW) / 2
    graphics.print(self.font, rerollText, rerollTextX, ry - 30, { r = 0.7, g = 0.7, b = 0.7, a = 1 })

    -- Draw Player's Jokers Section (at top, centered) using UILabels
    if JokerManager and JokerManager.slots then
        -- Update labels to match current joker state
        self:updateJokerLabels()
        
        local jokerSectionY = 120
        local mx, my = input.getMousePosition()
        
        -- Title centered above jokers
        local titleText = "Your Jokers:"
        local titleW = graphics.getTextSize(self.font, titleText)
        local titleX = (winW - titleW) / 2
        graphics.print(self.font, titleText, titleX, jokerSectionY, { r = 1, g = 1, b = 1, a = 1 })
        
        -- Sell mode instruction
        if self.sellMode then
            local instructText = "Click a joker to sell for " .. self.sellPrice .. "g"
            local instructW = graphics.getTextSize(self.font, instructText)
            local instructX = (winW - instructW) / 2
            graphics.print(self.font, instructText, instructX, jokerSectionY + 20, { r = 1, g = 0.8, b = 0.2, a = 1 })
        end
        
        -- Draw joker slots with labels
        for _, slot in ipairs(self.jokerLabels) do
            local label = slot.label
            local x = label.x
            local y = label.y
            local w = label.width
            local h = label.height
            
            -- Check hover
            local isHovered = mx >= x and mx <= x + w and my >= y and my <= y + h
            
            -- Background color
            local bgColor
            if slot.isEmpty then
                bgColor = { r = 0.1, g = 0.1, b = 0.15, a = 1 }
            else
                bgColor = { r = 0.2, g = 0.2, b = 0.25, a = 1 }
                if self.sellMode and isHovered then
                    bgColor = { r = 0.8, g = 0.3, b = 0.3, a = 1 }  -- Red hover in sell mode
                elseif isHovered then
                    bgColor = { r = 0.3, g = 0.3, b = 0.35, a = 1 }
                end
            end
            
            -- Draw slot background
            graphics.drawRect(x, y, w, h, bgColor, true)
            
            -- Draw border
            local borderColor = slot.isEmpty and { r = 0.3, g = 0.3, b = 0.3, a = 1 } or { r = 0.5, g = 0.5, b = 0.5, a = 1 }
            graphics.drawRect(x, y, w, h, borderColor, true)
            
            -- Draw label text (centered and wrapped if needed)
            label:draw()
        end
    end

    -- Buttons
    self.nextButton:draw()
    self.rerollButton:draw()
    self.sellButton:draw()

    -- Render Cards
    for _, card in ipairs(self.cards) do
        card:draw()
    end
end

return ShopUI
