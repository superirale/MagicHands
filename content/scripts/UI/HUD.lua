-- HUD.lua
-- Heads-up Display for score and status

HUD = class()

function HUD:init(font, smallFont)
    self.font = font
    self.smallFont = smallFont
end

function HUD:draw(state)
    local currentBlind = state:getCurrentBlind()
    -- Use global 'blind' module, passing the instance data 'currentBlind'
    local required = blind.getRequiredScore(currentBlind, state.difficulty)

    -- Top Bar background
    graphics.drawRect(0, 0, 1280, 80, { r = 0, g = 0, b = 0, a = 0.6 }, true)

    -- Blind Info
    graphics.print(self.font, "Blind: " .. currentBlind.type:upper(), 20, 20)
    graphics.print(self.smallFont, "Score: " .. state.currentScore .. " / " .. required, 20, 50)

    -- Stats
    graphics.print(self.smallFont, "Hands: " .. state.handsRemaining, 300, 30)
    graphics.print(self.smallFont, "Discards: " .. state.discardsRemaining, 450, 30)
    graphics.print(self.smallFont, "Gold: " .. Economy.gold, 600, 30)

    -- Act Info
    graphics.print(self.font, "Act " .. state.currentAct, 1150, 20)

    -- Boss Info (if active)
    local BossManager = require("criblage/BossManager")
    if BossManager.activeBoss then
        graphics.print(self.font, "BOSS: " .. BossManager.activeBoss.name, 500, 80, { r = 1, g = 0, b = 0, a = 1 })
        graphics.print(self.smallFont, BossManager.activeBoss.description, 500, 110, { r = 1, g = 0.5, b = 0.5, a = 1 })
    end

    -- Jokers Display (bottom left)
    local jokers = JokerManager:getJokers()
    if #jokers > 0 then
        graphics.print(self.font, "Jokers:", 20, 600, { r = 1, g = 0.8, b = 0, a = 1 })
        for i, jokerId in ipairs(jokers) do
            graphics.print(self.smallFont, (i) .. ". " .. jokerId, 20, 625 + (i - 1) * 20,
                { r = 0.9, g = 0.9, b = 0.9, a = 1 })
        end
    end

    -- Controls Help
    graphics.print(self.smallFont, "[Enter] Play Hand   [Backspace] Discard", 900, 680)
end

return HUD
