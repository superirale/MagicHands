-- HUD.lua
-- Heads-up Display for score and status

local HUD = class()

function HUD:init(font, smallFont, layout)
    self.font = font
    self.smallFont = smallFont
    self.layout = layout -- Store layout instance

    -- Register Layout Regions (Responsive Anchors)
    -- Top Bar elements
    self.layout:register("HUD_Blind", { anchor = "top-left", width = 200, height = 50, offsetX = 20, offsetY = 20 })
    self.layout:register("HUD_Hands", { anchor = "top-left", width = 100, height = 30, offsetX = 300, offsetY = 30 })
    self.layout:register("HUD_Discards", { anchor = "top-left", width = 100, height = 30, offsetX = 450, offsetY = 30 })
    self.layout:register("HUD_Gold", { anchor = "top-left", width = 100, height = 30, offsetX = 600, offsetY = 30 })

    -- Act Info (Top Right - approximate offset based on 1280 width)
    self.layout:register("HUD_Act", { anchor = "top-right", width = 100, height = 30, offsetX = 0, offsetY = 20 })

    -- Boss Info (Center-Top ish)
    self.layout:register("HUD_Boss", { anchor = "top-center", width = 300, height = 60, offsetX = 0, offsetY = 80 })

    -- Jokers (Bottom Left)
    self.layout:register("HUD_Jokers", { anchor = "bottom-left", width = 200, height = 100, offsetX = 20, offsetY = 0 })

    -- Controls (Bottom Right)
    self.layout:register("HUD_Controls", { anchor = "bottom-right", width = 380, height = 40, offsetX = 0, offsetY = 0 })
end

function HUD:draw(state)
    local currentBlind = state:getCurrentBlind()
    local required = blind.getRequiredScore(currentBlind, state.difficulty)

    -- Top Bar background (Responsive Width)
    local winW, winH = graphics.getWindowSize()
    graphics.drawRect(0, 0, winW, 80, { r = 0, g = 0, b = 0, a = 0.6 }, true)

    -- Blind Info
    local bx, by = self.layout:getPosition("HUD_Blind")
    graphics.print(self.font, "Blind: " .. currentBlind.type:upper(), bx, by)
    graphics.print(self.smallFont, "Score: " .. state.currentScore .. " / " .. required, bx, by + 30)

    -- Stats
    local hx, hy = self.layout:getPosition("HUD_Hands")
    graphics.print(self.smallFont, "Hands: " .. state.handsRemaining, hx, hy)
    local dx, dy = self.layout:getPosition("HUD_Discards")
    graphics.print(self.smallFont, "Discards: " .. state.discardsRemaining, dx, dy)
    local gx, gy = self.layout:getPosition("HUD_Gold")
    graphics.print(self.smallFont, "Gold: " .. Economy.gold, gx, gy)

    -- Act Info
    local ax, ay = self.layout:getPosition("HUD_Act")
    graphics.print(self.font, "Act " .. state.currentAct, ax, ay)

    -- Boss Info (if active)
    local BossManager = require("criblage/BossManager")
    if BossManager.activeBoss then
        local box, boy = self.layout:getPosition("HUD_Boss")
        graphics.print(self.font, "BOSS: " .. BossManager.activeBoss.name, box, boy, { r = 1, g = 0, b = 0, a = 1 })
        graphics.print(self.smallFont, BossManager.activeBoss.description, box, boy + 30,
            { r = 1, g = 0.5, b = 0.5, a = 1 })
    end

    -- Jokers Display
    local jokers = JokerManager:getJokers()
    if #jokers > 0 then
        local jx, jy = self.layout:getPosition("HUD_Jokers")
        graphics.print(self.font, "Jokers:", jx, jy - 100, { r = 1, g = 0.8, b = 0, a = 1 })
        for i, jokerId in ipairs(jokers) do
            graphics.print(self.smallFont, (i) .. ". " .. jokerId, jx, jy - 75 + (i - 1) * 20,
                { r = 0.9, g = 0.9, b = 0.9, a = 1 })
        end
    end

    -- Controls Help
    local cx, cy = self.layout:getPosition("HUD_Controls")
    graphics.print(self.smallFont, "[Enter] Play Hand   [Backspace] Discard", cx, cy)
end

return HUD
