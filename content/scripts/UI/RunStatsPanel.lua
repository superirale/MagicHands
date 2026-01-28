-- RunStatsPanel.lua
-- Display current run statistics

local RunStatsPanel = class()

function RunStatsPanel:init(font, smallFont)
    self.font = font
    self.smallFont = smallFont
    self.visible = false
    
    -- Stats to track
    self.stats = {
        handsPlayed = 0,
        discardsUsed = 0,
        highestScore = 0,
        totalScore = 0,
        goldEarned = 0,
        goldSpent = 0,
        itemsBought = 0,
        rerolls = 0,
        blindsWon = 0
    }
end

function RunStatsPanel:reset()
    for key, _ in pairs(self.stats) do
        self.stats[key] = 0
    end
end

function RunStatsPanel:increment(stat, amount)
    amount = amount or 1
    if self.stats[stat] then
        self.stats[stat] = self.stats[stat] + amount
    end
end

function RunStatsPanel:set(stat, value)
    if self.stats[stat] then
        self.stats[stat] = value
    end
end

function RunStatsPanel:get(stat)
    return self.stats[stat] or 0
end

function RunStatsPanel:toggle()
    self.visible = not self.visible
end

function RunStatsPanel:draw()
    if not self.visible then return end
    
    local x = 50
    local y = 150
    local w = 250
    local h = 400
    
    -- Background
    graphics.setColor(0.1, 0.1, 0.15, 0.95)
    graphics.rectangle("fill", x, y, w, h, 5)
    
    -- Border
    graphics.setColor(0.5, 0.7, 0.9, 1)
    graphics.rectangle("line", x, y, w, h, 5)
    
    -- Title
    graphics.setFont(self.font)
    graphics.setColor(1, 1, 1, 1)
    graphics.print("Run Statistics", x + 10, y + 10)
    
    -- Stats list
    graphics.setFont(self.smallFont)
    local statsY = y + 50
    local lineHeight = 25
    
    local statsList = {
        {label = "Hands Played", key = "handsPlayed"},
        {label = "Discards Used", key = "discardsUsed"},
        {label = "Blinds Won", key = "blindsWon"},
        {label = "Highest Score", key = "highestScore"},
        {label = "Total Score", key = "totalScore"},
        {label = "Gold Earned", key = "goldEarned"},
        {label = "Gold Spent", key = "goldSpent"},
        {label = "Items Bought", key = "itemsBought"},
        {label = "Shop Rerolls", key = "rerolls"}
    }
    
    for i, stat in ipairs(statsList) do
        local value = self.stats[stat.key]
        
        -- Label
        graphics.setColor(0.8, 0.8, 0.8, 1)
        graphics.print(stat.label, x + 15, statsY + (i - 1) * lineHeight)
        
        -- Value
        graphics.setColor(1, 1, 1, 1)
        graphics.print(tostring(value), x + w - 60, statsY + (i - 1) * lineHeight)
    end
    
    -- Close hint
    graphics.setColor(0.6, 0.6, 0.6, 1)
    graphics.print("Press TAB to close", x + 10, y + h - 25)
end

return RunStatsPanel
