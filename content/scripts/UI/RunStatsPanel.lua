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
    graphics.drawRect(x, y, w, h, {r = 0.1, g = 0.1, b = 0.15, a = 0.95}, true)
    
    -- Border
    graphics.drawRect(x, y, w, h, {r = 0.5, g = 0.7, b = 0.9, a = 1}, false)
    
    -- Title
    graphics.print(self.font, "Run Statistics", x + 10, y + 10, {r = 1, g = 1, b = 1, a = 1})
    
    -- Stats list
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
        graphics.print(self.smallFont, stat.label, x + 15, statsY + (i - 1) * lineHeight, {r = 0.8, g = 0.8, b = 0.8, a = 1})
        
        -- Value
        graphics.print(self.smallFont, tostring(value), x + w - 60, statsY + (i - 1) * lineHeight, {r = 1, g = 1, b = 1, a = 1})
    end
    
    -- Close hint
    graphics.print(self.smallFont, "Press TAB to close", x + 10, y + h - 25, {r = 0.6, g = 0.6, b = 0.6, a = 1})
end

return RunStatsPanel
