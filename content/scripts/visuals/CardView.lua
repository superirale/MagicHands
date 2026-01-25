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
end

function CardView:setCard(card)
    self.card = card
end

function CardView:update(dt, mx, my, clicked)
    self.hovered = self:isHovered(mx, my)

    -- Selection offset calculation
    if self.selected then
        self.targetY = self.y - 30
    elseif self.hovered then
        self.targetY = self.y - 10
    else
        self.targetY = self.y
    end

    -- Smooth movement (lerp)
    self.currentY = self.currentY + (self.targetY - self.currentY) * 10 * dt
end

function CardView:draw()
    -- Coordinate Conversion REMOVED. Assuming World Space ~ Screen Space (Top-Left 0,0)
    -- But avoiding DrawRect (Screen Space) which might occlude DrawSub (World Space).

    -- Draw sprite (World Space defaults)
    local r = self.card:getRank()
    local s = self.card:getSuit()
    local spriteX, spriteY = self:getSpriteCoords()

    local cardW = 1024 / 13
    local cardH = 1024 / 4

    -- Try Normalized UVs (0..1)
    local u = spriteX / 1024
    local v = spriteY / 1024
    local uw = cardW / 1024
    local vh = cardH / 1024

    graphics.drawSub(self.atlas,
        self.x, self.currentY, self.width, self.height, -- Dest
        u, v, uw, vh                                    -- Source (Normalized)
    )

    -- Draw Text Overlay (SCREEN SPACE) as fail-safe
    if self.font then
        local text = self.card:toString()
        local color = { r = 0, g = 0, b = 0, a = 1 }
        if s == 0 or s == 1 then color = { r = 1, g = 0, b = 0, a = 1 } end
        graphics.print(self.font, text, self.x + 5, self.currentY + 5, color)
    end

    -- Visual selection highlight (Screen Space)
    if self.selected then
        graphics.drawRect(self.x - 2, self.currentY - 2, self.width + 4, self.height + 4,
            { r = 1, g = 1, b = 0.2, a = 0.5 },
            true)
    end
end

function CardView:getSpriteCoords()
    -- Get integer values
    local r = self.card:getRank()
    local s = self.card:getSuit() -- 0=H, 1=D, 2=C, 3=S

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
    return mx >= self.x and mx <= self.x + self.width and
        my >= self.currentY and my <= self.currentY + self.height
end

function CardView:toggleSelected()
    self.selected = not self.selected
end

function CardView:setSelected(val)
    self.selected = val
end

return CardView
