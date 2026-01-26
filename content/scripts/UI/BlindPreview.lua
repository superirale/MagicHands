-- BlindPreview.lua
-- UI Screen shown before a blind starts

local BlindPreview = class()

function BlindPreview:init(font, smallFont)
    self.font = font
    self.smallFont = smallFont
    self.active = false
    self.blindData = nil
    self.reward = 0
end

function BlindPreview:show(blindData, reward)
    self.blindData = blindData
    self.reward = reward
    self.active = true
end

function BlindPreview:hide()
    self.active = false
end

function BlindPreview:update(dt, mx, my, clicked)
    if not self.active then return false end

    -- Check for Play Button click or Enter key
    -- Button Rect: Center X, ~500 Y, 200x60
    local btnX, btnY, btnW, btnH = 540, 500, 200, 60

    local hover = mx >= btnX and mx <= btnX + btnW and my >= btnY and my <= btnY + btnH

    if (clicked and hover) or input.isPressed("return") then
        return true -- signal to start
    end

    return false
end

function BlindPreview:draw()
    if not self.active or not self.blindData then return end

    -- Darken background
    graphics.drawRect(0, 0, 1280, 720, { r = 0, g = 0, b = 0, a = 0.85 }, true)

    -- Window Frame
    graphics.drawRect(340, 100, 600, 520, { r = 0.2, g = 0.2, b = 0.25, a = 1 }, true)
    graphics.drawRect(340, 100, 600, 520, { r = 0.8, g = 0.7, b = 0.4, a = 1 }, false) -- Border

    -- Title
    local title = "BLIND: " .. self.blindData.type:upper()
    graphics.print(self.font, title, 500, 140, { r = 1, g = 0.9, b = 0.6, a = 1 })

    -- Target Score
    local required = blind.getRequiredScore(self.blindData, 1.0) -- Assuming difficulty 1.0 for display
    graphics.print(self.font, "Goal: " .. required, 550, 220, { r = 1, g = 0.3, b = 0.3, a = 1 })

    -- Reward
    graphics.print(self.smallFont, "Reward: " .. self.reward .. "g", 580, 280, { r = 1, g = 0.8, b = 0, a = 1 })

    -- Boss Description
    if self.blindData.type == "boss" and self.blindData.bossId ~= "" then
        local BossManager = require("criblage/BossManager")
        local boss = BossManager:loadBoss(self.blindData.bossId)
        if boss then
            graphics.print(self.font, boss.name, 550, 340, { r = 0.8, g = 0.2, b = 0.2, a = 1 })
            graphics.print(self.smallFont, boss.description, 450, 380, { r = 0.9, g = 0.9, b = 0.9, a = 1 })
        end
    else
        graphics.print(self.smallFont, "Standard Rules", 560, 360, { r = 0.6, g = 0.6, b = 0.6, a = 1 })
    end

    -- Play Button
    graphics.drawRect(540, 500, 200, 60, { r = 0.3, g = 0.6, b = 0.3, a = 1 }, true)
    graphics.print(self.font, "PLAY", 600, 515, { r = 1, g = 1, b = 1, a = 1 })
    graphics.print(self.smallFont, "[Enter]", 610, 580, { r = 0.5, g = 0.5, b = 0.5, a = 1 })
end

return BlindPreview
