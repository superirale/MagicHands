-- AchievementNotification.lua
-- Popup notification when achievements are unlocked

local AchievementNotification = class()

function AchievementNotification:init(font, smallFont)
    self.font = font or 0
    self.smallFont = smallFont or font or 0
    self.queue = {}
    self.current = nil
    self.displayTime = 4.0 -- seconds
    self.timer = 0
    self.y = -100 -- Start off screen
    self.targetY = 50
end

-- Add achievement to notification queue
function AchievementNotification:notify(achievement)
    table.insert(self.queue, {
        name = achievement.name,
        description = achievement.description,
        reward = achievement.reward
    })
end

function AchievementNotification:update(dt)
    -- Show next notification if queue has items
    if not self.current and #self.queue > 0 then
        self.current = table.remove(self.queue, 1)
        self.timer = self.displayTime
        self.y = -100
    end
    
    -- Animate current notification
    if self.current then
        -- Slide in
        if self.y < self.targetY then
            self.y = self.y + 300 * dt
            if self.y > self.targetY then
                self.y = self.targetY
            end
        end
        
        -- Count down timer
        self.timer = self.timer - dt
        
        -- Slide out when timer expires
        if self.timer <= 0.5 then
            self.y = self.y - 400 * dt
            if self.y < -100 then
                self.current = nil
            end
        end
    end
end

function AchievementNotification:draw()
    if not self.current then return end
    
    local x = 400
    local y = self.y
    local w = 480
    local h = 100
    
    -- Shadow
    graphics.setColor(0, 0, 0, 0.5)
    graphics.rectangle("fill", x + 5, y + 5, w, h, 8)
    
    -- Background
    graphics.setColor(0.15, 0.15, 0.25, 0.95)
    graphics.rectangle("fill", x, y, w, h, 8)
    
    -- Gold border
    graphics.setColor(1, 0.8, 0.2, 1)
    graphics.rectangle("line", x, y, w, h, 8)
    graphics.rectangle("line", x + 2, y + 2, w - 4, h - 4, 6)
    
    -- Trophy icon area
    graphics.setColor(1, 0.8, 0.2, 0.3)
    graphics.circle("fill", x + 50, y + 50, 30)
    
    -- Trophy emoji/icon
    graphics.setColor(1, 1, 1, 1)
    graphics.setFont(self.font)
    graphics.print("🏆", x + 35, y + 30)
    
    -- Text
    graphics.setColor(1, 1, 1, 1)
    graphics.print("Achievement Unlocked!", x + 100, y + 15)
    
    graphics.setColor(1, 0.9, 0.4, 1)
    graphics.print(self.current.name, x + 100, y + 40)
    
    graphics.setColor(0.8, 0.8, 0.8, 1)
    graphics.print(self.current.description, x + 100, y + 65)
end

return AchievementNotification
