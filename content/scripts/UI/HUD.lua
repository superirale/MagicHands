-- HUD.lua
-- Heads-up Display for score and status

HUD = class()

local UILayout = require("UI.UILayout")

function HUD:init(font, smallFont)
    self.font = font
    self.smallFont = smallFont

    -- Register Layout Regions (Responsive Anchors)
    -- Top Bar elements
    UILayout.register("HUD_Blind", { anchor = "top-left", width = 200, height = 50, offsetX = 20, offsetY = 20 })
    UILayout.register("HUD_Hands", { anchor = "top-left", width = 100, height = 30, offsetX = 300, offsetY = 30 })
    UILayout.register("HUD_Discards", { anchor = "top-left", width = 100, height = 30, offsetX = 450, offsetY = 30 })
    UILayout.register("HUD_Gold", { anchor = "top-left", width = 100, height = 30, offsetX = 600, offsetY = 30 })

    -- Act Info (Top Right - approximate offset based on 1280 width)
    -- 1150 is 130px from right.
    UILayout.register("HUD_Act", { anchor = "top-right", width = 100, height = 30, offsetX = 0, offsetY = 20 })

    -- Boss Info (Center-Top ish)
    UILayout.register("HUD_Boss", { anchor = "top-center", width = 300, height = 60, offsetX = 0, offsetY = 80 })

    -- Jokers (Bottom Left)
    UILayout.register("HUD_Jokers", { anchor = "bottom-left", width = 200, height = 100, offsetX = 20, offsetY = 0 })

    -- Controls (Bottom Right)
    -- 900 is 380px from right. 680 is 40px from bottom.
    UILayout.register("HUD_Controls", { anchor = "bottom-right", width = 380, height = 40, offsetX = 0, offsetY = 0 })
end

function HUD:draw(state)
    local currentBlind = state:getCurrentBlind()
    local required = blind.getRequiredScore(currentBlind, state.difficulty)

    -- Top Bar background (Responsive Width)
    local winW, winH = graphics.getWindowSize()
    graphics.drawRect(0, 0, winW, 80, { r = 0, g = 0, b = 0, a = 0.6 }, true)

    -- Blind Info
    local bx, by = UILayout.getPosition("HUD_Blind")
    graphics.print(self.font, "Blind: " .. currentBlind.type:upper(), bx, by)
    graphics.print(self.smallFont, "Score: " .. state.currentScore .. " / " .. required, bx, by + 30)

    -- Stats
    local hx, hy = UILayout.getPosition("HUD_Hands")
    graphics.print(self.smallFont, "Hands: " .. state.handsRemaining, hx, hy)
    local dx, dy = UILayout.getPosition("HUD_Discards")
    graphics.print(self.smallFont, "Discards: " .. state.discardsRemaining, dx, dy)
    local gx, gy = UILayout.getPosition("HUD_Gold")
    graphics.print(self.smallFont, "Gold: " .. Economy.gold, gx, gy)

    -- Act Info
    local ax, ay = UILayout.getPosition("HUD_Act")
    graphics.print(self.font, "Act " .. state.currentAct, ax, ay)

    -- Boss Info (if active)
    local BossManager = require("criblage/BossManager")
    if BossManager.activeBoss then
        local box, boy = UILayout.getPosition("HUD_Boss")
        graphics.print(self.font, "BOSS: " .. BossManager.activeBoss.name, box, boy, { r = 1, g = 0, b = 0, a = 1 })
        graphics.print(self.smallFont, BossManager.activeBoss.description, box, boy + 30,
            { r = 1, g = 0.5, b = 0.5, a = 1 })
    end

    -- Jokers Display
    local jokers = JokerManager:getJokers()
    if #jokers > 0 then
        local jx, jy = UILayout.getPosition("HUD_Jokers")
        -- Adjust Y to draw upwards from bottom? No, draw down from position.
        -- Anchor bottom-left returns (padding, H - padding - h). The top-left of the region box.
        graphics.print(self.font, "Jokers:", jx, jy - 100, { r = 1, g = 0.8, b = 0, a = 1 }) -- Move up a bit?
        -- Actually let's assume jy is the top of the reserved area.
        for i, jokerId in ipairs(jokers) do
            graphics.print(self.smallFont, (i) .. ". " .. jokerId, jx, jy - 75 + (i - 1) * 20,
                { r = 0.9, g = 0.9, b = 0.9, a = 1 })
        end
    end

    -- Controls Help
    local cx, cy = UILayout.getPosition("HUD_Controls")
    graphics.print(self.smallFont, "[Enter] Play Hand   [Backspace] Discard", cx, cy)
end

return HUD
