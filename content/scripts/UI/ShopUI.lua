-- ShopUI.lua
-- Visual shop interface

ShopUI = class()

function ShopUI:init(font)
    self.font = font
    self.active = false
    self.reward = 0
end

function ShopUI:open(reward)
    self.active = true
    self.reward = reward
    Shop:generateJokers(CampaignState.currentAct)
end

function ShopUI:update(dt, mx, my, clicked)
    if not self.active then return false end

    -- Check clicks on jokers (Simple layout)
    local startX = 300
    local spacing = 220

    if clicked then
        -- Check buy buttons
        for i, joker in ipairs(Shop.jokers) do
            local x = startX + (i - 1) * spacing
            local y = 300

            if mx >= x and mx <= x + 200 and my >= y and my <= y + 250 then
                local result, msg = Shop:buyJoker(i)
                -- Check if result is a signal (table)
                if type(result) == "table" and result.action == "select_card" then
                    return result
                end
            end
        end

        -- Next Round Button
        if mx >= 1000 and mx <= 1200 and my >= 600 and my <= 660 then
            return { action = "close" } -- Close shop
        end
    end

    return false
end

function ShopUI:draw()
    if not self.active then return end

    -- Overlay
    graphics.drawRect(0, 0, 1280, 720, { r = 0, g = 0, b = 0.1, a = 0.9 }, true)

    -- Title
    graphics.print(self.font, "SHOP", 600, 50)
    graphics.print(self.font, "Gold: " .. Economy.gold, 600, 100)

    -- Render Jokers
    local startX = 300
    local spacing = 220

    for i, joker in ipairs(Shop.jokers) do
        local x = startX + (i - 1) * spacing
        local y = 300

        -- Card background
        graphics.drawRect(x, y, 200, 250, { r = 0.2, g = 0.2, b = 0.2, a = 1 }, true)

        -- Joker Name
        graphics.print(self.font, joker.id, x + 10, y + 20)

        -- Price
        graphics.print(self.font, joker.price .. "g", x + 10, y + 200)

        -- Buy hint
        graphics.print(self.font, "Click to Buy", x + 10, y + 220, { r = 0.5, g = 1, b = 0.5 })
    end

    -- Next Round Button
    graphics.drawRect(1000, 600, 200, 60, { r = 0.8, g = 0.2, b = 0.2, a = 1 }, true)
    graphics.print(self.font, "Next Round >", 1030, 615)
end

return ShopUI
