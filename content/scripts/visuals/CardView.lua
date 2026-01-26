-- CardView.lua
-- Visual representation of a playing card

CardView = class()

function CardView:init(card, x, y, atlas, font)
    self.card = card
    self.x = x
    self.y = y
    self.width = 100
    self.height = 140
    self.atlas = atlas
    self.font = font
    self.selected = false
    self.hovered = false

    -- Animation state
    self.targetY = y
    self.currentY = y
    self.targetX = x
    self.currentX = x

    self.isDragging = false
end

function CardView:setCard(card)
    self.card = card
end

function CardView:update(dt, mx, my, clicked)
    self.hovered = self:isHovered(mx, my)

    -- Selection offset calculation
    if not self.isDragging then
        if self.selected then
            self.targetY = self.y - 30
        elseif self.hovered then
            self.targetY = self.y - 10
        else
            self.targetY = self.y
        end

        -- Target X is usually just self.x (grid position) unless moved
        self.targetX = self.x
    end

    -- Smooth movement (lerp)
    -- If dragging, currentX/Y are set directly by GameScene, so we skip lerp?
    -- Actually GameScene updates X/Y directly for drag, but we want lerp for SNAP BACK or REORDER
    -- So: If dragging, we might set currentX directly. If not, we lerp to targetX.

    if not self.isDragging then
        self.currentX = self.currentX + (self.targetX - self.currentX) * 15 * dt
        self.currentY = self.currentY + (self.targetY - self.currentY) * 15 * dt
    end
end

function CardView:draw()
    -- Coordinate Conversion REMOVED. Assuming World Space ~ Screen Space (Top-Left 0,0)
    -- But avoiding DrawRect (Screen Space) which might occlude DrawSub (World Space).

    -- Draw sprite (World Space defaults)
    local r, s = self:getCardValues()
    local spriteX, spriteY = self:getSpriteCoords(r, s)

    local cardW = 1024 / 13
    local cardH = 1024 / 4

    -- Use PIXEL coordinates for DrawSub (Engine expects pixels, not UVs)
    local u = spriteX
    local v = spriteY
    local uw = cardW
    local vh = cardH

    graphics.drawSub(self.atlas,
        self.currentX, self.currentY, self.width, self.height, -- Dest
        u, v, uw, vh                                           -- Source (Pixels)
    )

    -- Draw Text Overlay (SCREEN SPACE) as fail-safe
    if self.font then
        local text = ""
        if self.card.rank then
            text = self.card.rank .. self.card.suit
        elseif self.card.toString then
            text = self.card:toString()
        end

        local color = { r = 0, g = 0, b = 0, a = 1 }
        -- Red suits: Hearts(0), Diamonds(1) -> based on conversion logic below
        -- My strings: H, D
        if s == 0 or s == 1 then color = { r = 1, g = 0, b = 0, a = 1 } end

        graphics.print(self.font, text, self.currentX + 5, self.currentY + 5, color)
    end

    -- Visual selection highlight (Screen Space)
    if self.selected then
        graphics.drawRect(self.currentX - 2, self.currentY - 2, self.width + 4, self.height + 4,
            { r = 1, g = 1, b = 0.2, a = 0.5 },
            true)
    end
end

function CardView:getCardValues()
    -- Handle Class Object (Legacy)
    if self.card.getRank then
        return self.card:getRank(), self.card:getSuit()
    end

    -- Handle Table Data (Strings: A,2..K, H,D,S,C)
    local rStr = self.card.rank
    local sStr = self.card.suit

    local rInt = 1
    if rStr == "A" then
        rInt = 1
    elseif rStr == "J" then
        rInt = 11
    elseif rStr == "Q" then
        rInt = 12
    elseif rStr == "K" then
        rInt = 13
    else
        rInt = tonumber(rStr) or 1
    end

    local sInt = 0
    if sStr == "H" then sInt = 0 end
    if sStr == "D" then sInt = 1 end
    if sStr == "C" then sInt = 2 end
    if sStr == "S" then sInt = 3 end

    return rInt, sInt
end

function CardView:getSpriteCoords(r, s)
    -- If valid r,s passed, use them. Else fetch.
    if not r then r, s = self:getCardValues() end

    -- Generated Sheet Layout:
    -- Row 0: Spades (s=3)
    -- Row 1: Clubs (s=2)
    -- Row 2: Hearts (s=0)
    -- Row 3: Diamonds (s=1)

    local row = 0
    if s == 3 then row = 0 end
    if s == 2 then row = 1 end
    if s == 0 then row = 2 end
    if s == 1 then row = 3 end

    -- Rank: 1(Ace)..13(King) -> Col 0..12
    local col = r - 1

    local cardW = 1024 / 13
    local cardH = 1024 / 4

    return col * cardW, row * cardH
end

function CardView:isHovered(mx, my)
    return mx >= self.currentX and mx <= self.currentX + self.width and
        my >= self.currentY and my <= self.currentY + self.height
end

function CardView:toggleSelected()
    self.selected = not self.selected
end

function CardView:setSelected(val)
    self.selected = val
end

return CardView
