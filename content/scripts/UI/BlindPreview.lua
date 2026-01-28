-- BlindPreview.lua
-- UI Screen shown before a blind starts

local BlindPreview = class()
local UIButton = require("UI.elements.UIButton")

function BlindPreview:init(font, smallFont, layout)
    self.font = font
    self.smallFont = smallFont
    self.layout = layout -- Store layout instance
    self.active = false
    self.blindData = nil
    self.reward = 0
    self.shouldStartBlind = false

    -- Register the modal layout
    self.layoutName = "BlindPreviewModal"
    self.width = 600
    self.height = 520

    self.layout:register(self.layoutName, {
        anchor = "center",
        width = self.width,
        height = self.height
    })

    -- Button dims
    self.btnWidth = 200
    self.btnHeight = 60
    
    -- Create Play Button (without layout - we'll position it manually)
    self.playButton = UIButton(nil, "PLAY", font, function()
        self.shouldStartBlind = true
    end)
    
    -- Set button dimensions
    self.playButton.width = self.btnWidth
    self.playButton.height = self.btnHeight
    
    -- Customize button colors (green theme)
    self.playButton.bgColor = { r = 0.3, g = 0.6, b = 0.3, a = 1 }
    self.playButton.hoverColor = { r = 0.4, g = 0.8, b = 0.4, a = 1 }
end

function BlindPreview:show(blindData, reward)
    self.blindData = blindData
    self.reward = reward
    self.active = true
    self.shouldStartBlind = false
    self.playButton.visible = true
end

function BlindPreview:hide()
    self.active = false
    self.playButton.visible = false
end

function BlindPreview:update(dt, mx, my, clicked)
    if not self.active then return false end

    -- Reset the flag
    self.shouldStartBlind = false
    
    -- Get modal position
    local x, y = self.layout:getPosition(self.layoutName)
    
    -- Position button at bottom center of modal
    self.playButton.x = x + (self.width - self.btnWidth) / 2
    self.playButton.y = y + self.height - self.btnHeight - 40
    
    -- Update the play button
    self.playButton:update(dt, mx, my, clicked)
    
    -- Also check for Enter key
    if input.isPressed("return") then
        self.shouldStartBlind = true
    end
    
    return self.shouldStartBlind
end

function BlindPreview:draw()
    if not self.active or not self.blindData then return end

    local x, y = self.layout:getPosition(self.layoutName)
    local w, h = self.width, self.height

    -- 1. Full Screen Dim Overlay
    graphics.drawRect(0, 0, self.layout.screenWidth, self.layout.screenHeight, { r = 0, g = 0, b = 0, a = 0.85 }, true)

    -- 2. Modal Window Background
    -- Theme colors based on blind type
    local isBoss = self.blindData.type == "boss"
    local bgColor = isBoss and { r = 0.15, g = 0.05, b = 0.05, a = 1 } or { r = 0.1, g = 0.1, b = 0.15, a = 1 }
    local borderColor = isBoss and { r = 0.8, g = 0.2, b = 0.2, a = 1 } or { r = 0.4, g = 0.6, b = 0.8, a = 1 }

    graphics.drawRect(x, y, w, h, bgColor, true)

    -- Border (thick, simulated)
    for i = 0, 2 do
        graphics.drawRect(x - i, y - i, w + i * 2, h + i * 2, borderColor, false)
    end

    -- 3. Content
    local cx = x + w / 2 -- Center X

    -- Title
    local title = "BLIND: " .. self.blindData.type:upper()
    local titleColor = { r = 1, g = 1, b = 1, a = 1 }
    local titleW = graphics.getTextSize(self.font, title)
    graphics.print(self.font, title, cx - titleW / 2, y + 40, titleColor)

    -- Separator
    graphics.drawRect(x + 50, y + 80, w - 100, 2, { r = 0.5, g = 0.5, b = 0.5, a = 0.5 }, true)

    -- Target Score
    local required = blind.getRequiredScore(self.blindData, 1.0) -- Assuming difficulty 1.0 for display
    local goalText = "Goal: " .. required
    local goalColor = { r = 1, g = 0.3, b = 0.3, a = 1 }         -- Reddish
    local goalW = graphics.getTextSize(self.font, goalText)
    graphics.print(self.font, goalText, cx - goalW / 2, y + 110, goalColor)

    -- Reward
    local rewardText = "Reward: " .. self.reward .. "g"
    local rewardColor = { r = 1, g = 0.8, b = 0, a = 1 } -- Gold
    local rewardW = graphics.getTextSize(self.smallFont, rewardText)
    graphics.print(self.smallFont, rewardText, cx - rewardW / 2, y + 150, rewardColor)

    -- Boss Description Area
    if isBoss and self.blindData.bossId ~= "" then
        local BossManager = require("criblage/BossManager")
        local boss = BossManager:loadBoss(self.blindData.bossId)
        if boss then
            -- Boss Name
            local nameW = graphics.getTextSize(self.font, boss.name)
            graphics.print(self.font, boss.name, cx - nameW / 2, y + 220, borderColor)

            -- Description Box
            local descBoxY = y + 260
            local descBoxH = 80
            graphics.drawRect(x + 60, descBoxY, w - 120, descBoxH, { r = 0, g = 0, b = 0, a = 0.3 }, true)

            -- Description Text (Centered)
            local descW = graphics.getTextSize(self.smallFont, boss.description)
            graphics.print(self.smallFont, boss.description, cx - descW / 2, descBoxY + (descBoxH - 16) / 2,
                { r = 0.9, g = 0.9, b = 0.9, a = 1 })
        end
    else
        -- Standard Text
        local stdText = "Standard Rules"
        local stdW = graphics.getTextSize(self.smallFont, stdText)
        graphics.print(self.smallFont, stdText, cx - stdW / 2, y + 240, { r = 0.6, g = 0.6, b = 0.6, a = 1 })
    end

    -- 4. Draw Play Button using UIButton component
    self.playButton:draw()

    -- Draw hint text below button
    local hintText = "[Enter]"
    local hintW = graphics.getTextSize(self.smallFont, hintText)
    graphics.print(self.smallFont, hintText, cx - hintW / 2, self.playButton.y + self.btnHeight + 10,
        { r = 0.5, g = 0.5, b = 0.5, a = 1 })
end

return BlindPreview
