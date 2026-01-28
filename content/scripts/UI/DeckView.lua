-- DeckView.lua
-- UI Component for viewing and interacting with the deck

local CardView = require("visuals/CardView")

local DeckView = class()

function DeckView:init(font, smallFont, cardAtlas)
    self.font = font
    self.smallFont = smallFont
    self.cardAtlas = cardAtlas
    self.visible = false
    self.cards = {}
    self.mode = "VIEW"        -- VIEW, SELECT
    self.onCardSelected = nil -- Callback
    self.onClose = nil        -- Callback
end

function DeckView:show(deckList, mode, onCardSelected, onClose)
    self.visible = true
    self.mode = mode or "VIEW"
    self.onCardSelected = onCardSelected
    self.onClose = onClose

    self.cards = {}
    local startX = 100
    local startY = 150
    local spacingX = 85
    local spacingY = 110
    local cols = 13

    -- Sort deckList by Rank then Suit
    local toShow = {}
    for _, card in ipairs(deckList) do
        table.insert(toShow, card)
    end

    table.sort(toShow, function(a, b)
        local function getRankVal(rStr)
            if rStr == "A" then return 1 end
            if rStr == "J" then return 11 end
            if rStr == "Q" then return 12 end
            if rStr == "K" then return 13 end
            return tonumber(rStr) or 0
        end
        local function getSuitVal(sStr)
            if sStr == "S" then return 4 end
            if sStr == "H" then return 3 end
            if sStr == "C" then return 2 end
            if sStr == "D" then return 1 end
            return 0
        end

        local ra, rb = getRankVal(a.rank), getRankVal(b.rank)
        local sa, sb = getSuitVal(a.suit), getSuitVal(b.suit)

        if sa ~= sb then return sa > sb end -- Group by Suit (S, H, C, D)
        return ra < rb                      -- Then by Rank (A..K)
    end)

    for i, cardData in ipairs(toShow) do
        local row = math.floor((i - 1) / cols)
        local col = (i - 1) % cols

        local x = startX + col * spacingX
        local y = startY + row * spacingY

        local view = CardView(cardData, x, y, self.cardAtlas, self.smallFont)
        -- Keep index proportional to ORIGINAL list?
        -- Problem: If we sort, the index 'i' here is the sorted index.
        -- If user sorts and selects index 5, it matches sorted list index 5.
        -- When we pass callback(index), the caller (GameScene) expects index in MASTER DECK?
        -- CampaignState:removeCard(index) removes by index.
        -- If we display sorted, we need to know the ORIGINAL index.
        -- We should store original index in 'toShow'.

        -- Re-map: Find original index of this cardData object in deckList
        -- Assuming cardData table ref is unique/stable or we scan.
        -- deckList passed in is CampaignState.masterDeck.
        -- Let's find it.
        local originalIndex = 0
        for k, v in ipairs(deckList) do
            if v == cardData then -- Object identity check
                originalIndex = k
                break
            end
        end

        table.insert(self.cards, { view = view, data = cardData, index = originalIndex })
    end
end

function DeckView:hide()
    self.visible = false
    self.cards = {}
end

function DeckView:update(dt)
    if not self.visible then return end

    -- Mouse interaction
    local mx, my = input.getMousePosition()
    local clicked = input.isMouseJustPressed(1) -- Left click

    for _, item in ipairs(self.cards) do
        local view = item.view
        -- Simple AABB check (CardView typically doesn't expose bounds easily without looking, assuming 71x96 roughly or similar)
        -- Let's assume standard poker card size scaled.
        -- CardView probably has width/height. If not, we guess.
        local w, h = 71, 96
        if view.width then w = view.width end
        if view.height then h = view.height end

        if mx >= view.x and mx <= view.x + w and my >= view.y and my <= view.y + h then
            if clicked then
                if self.mode == "SELECT" and self.onCardSelected then
                    self.onCardSelected(item.index, item.data)
                    self:hide() -- Auto hide on select? Or let caller handle?
                    -- Caller should handle.
                end
            end
        end
    end

    -- Right click to close/back?
    if input.isMouseJustPressed(2) or input.isKeyJustPressed("escape") then
        if self.onClose then self.onClose() end
        self:hide()
    end
end

function DeckView:draw()
    if not self.visible then return end

    -- Dim background
    graphics.setColor(0, 0, 0, 0.8)
    graphics.rectangle("fill", 0, 0, 1280, 720)
    graphics.setColor(1, 1, 1, 1)

    -- Title
    local title = "Deck View"
    if self.mode == "SELECT" then title = "Select a Card" end
    graphics.setFont(self.font)
    graphics.print(title, 100, 50)

    graphics.setFont(self.smallFont)
    graphics.print("Press ESC or Right Click to close", 100, 90)

    -- Draw cards
    for _, item in ipairs(self.cards) do
        item.view:draw()

        -- Highlight if mode is select
        if self.mode == "SELECT" then
            local mx, my = input.getMousePosition()
            local w, h = 71, 96
            if item.view.width then w = item.view.width end
            if item.view.height then h = item.view.height end

            if mx >= item.view.x and mx <= item.view.x + w and my >= item.view.y and my <= item.view.y + h then
                graphics.setColor(1, 1, 0, 0.5)
                graphics.rectangle("line", item.view.x, item.view.y, w, h)
                graphics.setColor(1, 1, 1, 1)
            end
        end
    end
end

return DeckView
