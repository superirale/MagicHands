-- CollectionUI.lua
-- Collection browser and achievement viewer

local CollectionUI = class()

function CollectionUI:init(font, smallFont)
    self.font = font
    self.smallFont = smallFont
    self.visible = false

    -- Tabs
    self.currentTab = "achievements" -- "achievements", "jokers", "planets", "warps", "imprints", "sculptors"
    self.tabs = { "achievements", "jokers", "planets", "warps", "imprints", "sculptors" }

    -- Scroll state
    self.scrollOffset = 0
    self.maxScroll = 0

    -- Cache
    self.achievementsList = {}
    self.collectionData = {}
end

function CollectionUI:show()
    self.visible = true
    self.scrollOffset = 0
    self:refreshData()
end

function CollectionUI:open()
    self:show()
end

function CollectionUI:hide()
    self.visible = false
end

function CollectionUI:close()
    self:hide()
end

function CollectionUI:toggle()
    if self.visible then
        self:hide()
    else
        self:show()
    end
end

function CollectionUI:refreshData()
    -- Get achievements
    if MagicHandsAchievements then
        self.achievementsList = {}
        local allAch = MagicHandsAchievements:getAll()
        for id, ach in pairs(allAch) do
            if not ach.hidden or ach.unlocked then
                table.insert(self.achievementsList, ach)
            end
        end

        -- Sort by unlocked status, then name
        table.sort(self.achievementsList, function(a, b)
            if a.unlocked ~= b.unlocked then
                return a.unlocked
            end
            return a.name < b.name
        end)
    end

    -- Get collection data
    if UnlockSystem then
        self.collectionData = {
            jokers = UnlockSystem:getUnlocked("jokers"),
            planets = UnlockSystem:getUnlocked("planets"),
            warps = UnlockSystem:getUnlocked("warps"),
            imprints = UnlockSystem:getUnlocked("imprints"),
            sculptors = UnlockSystem:getUnlocked("sculptors")
        }
    end
end

function CollectionUI:update(dt)
    if not self.visible then return end

    local mx, my = input.getMousePosition()
    local clicked = input.isMouseButtonPressed("left")

    -- Tab switching
    local tabY = 100
    local tabX = 50
    local tabWidth = 150
    local tabHeight = 40

    for i, tab in ipairs(self.tabs) do
        local tx = tabX + (i - 1) * (tabWidth + 10)
        if mx >= tx and mx <= tx + tabWidth and my >= tabY and my <= tabY + tabHeight then
            if clicked then
                self.currentTab = tab
                self.scrollOffset = 0
            end
        end
    end

    -- Mouse wheel scrolling
    -- Note: Would need mouse wheel input binding

    -- Close button
    if input.isPressed("escape") or input.isPressed("c") then
        self:hide()
        return "close"
    end
end

function CollectionUI:draw()
    if not self.visible then return end

    -- Dim background
    graphics.setColor(0, 0, 0, 0.9)
    graphics.rectangle("fill", 0, 0, 1280, 720)
    graphics.setColor(1, 1, 1, 1)

    -- Title
    graphics.setFont(self.font)
    graphics.print("COLLECTION", 50, 30)

    -- Progress summary
    if MagicHandsAchievements then
        local progress = MagicHandsAchievements:getProgress()
        local unlocked = MagicHandsAchievements:countUnlocked()
        local total = MagicHandsAchievements:count()

        graphics.setFont(self.smallFont)
        graphics.print(string.format("Achievements: %d/%d (%.1f%%)", unlocked, total, progress), 500, 40)
    end

    if UnlockSystem then
        local totalUnlocked = UnlockSystem:getTotalUnlocked()
        graphics.print(string.format("Cards Unlocked: %d/121", totalUnlocked), 800, 40)
    end

    -- Tabs
    self:drawTabs()

    -- Content area
    local contentY = 160

    if self.currentTab == "achievements" then
        self:drawAchievements(contentY)
    else
        self:drawCollection(contentY, self.currentTab)
    end

    -- Close hint
    graphics.setFont(self.smallFont)
    graphics.print("Press ESC or C to close", 50, 680)
end

function CollectionUI:drawTabs()
    local tabY = 100
    local tabX = 50
    local tabWidth = 150
    local tabHeight = 40

    for i, tab in ipairs(self.tabs) do
        local tx = tabX + (i - 1) * (tabWidth + 10)

        -- Tab background
        if tab == self.currentTab then
            graphics.setColor(0.3, 0.3, 0.5, 1)
        else
            graphics.setColor(0.15, 0.15, 0.2, 1)
        end
        graphics.rectangle("fill", tx, tabY, tabWidth, tabHeight)

        -- Tab border
        graphics.setColor(1, 1, 1, 1)
        graphics.rectangle("line", tx, tabY, tabWidth, tabHeight)

        -- Tab text
        graphics.setFont(self.smallFont)
        local label = tab:gsub("^%l", string.upper)
        graphics.print(label, tx + 10, tabY + 12)
    end
end

function CollectionUI:drawAchievements(startY)
    local y = startY - self.scrollOffset
    local itemHeight = 80

    graphics.setFont(self.smallFont)

    for i, ach in ipairs(self.achievementsList) do
        if y > 150 and y < 700 then
            -- Achievement box
            if ach.unlocked then
                graphics.setColor(0.2, 0.4, 0.2, 0.8)
            else
                graphics.setColor(0.2, 0.2, 0.2, 0.8)
            end
            graphics.rectangle("fill", 50, y, 1180, itemHeight - 10)

            -- Border
            if ach.unlocked then
                graphics.setColor(0.4, 0.8, 0.4, 1)
            else
                graphics.setColor(0.4, 0.4, 0.4, 1)
            end
            graphics.rectangle("line", 50, y, 1180, itemHeight - 10)

            -- Icon area (placeholder)
            graphics.setColor(0.3, 0.3, 0.3, 1)
            graphics.rectangle("fill", 60, y + 10, 50, 50)

            -- Achievement name
            graphics.setColor(1, 1, 1, 1)
            graphics.setFont(self.font)
            local prefix = ach.unlocked and "✓ " or "🔒 "
            graphics.print(prefix .. ach.name, 120, y + 5)

            -- Description
            graphics.setFont(self.smallFont)
            graphics.setColor(0.8, 0.8, 0.8, 1)
            graphics.print(ach.description, 120, y + 30)

            -- Category badge
            graphics.setColor(0.5, 0.5, 0.7, 1)
            graphics.print("[" .. ach.category .. "]", 120, y + 50)

            -- Reward
            if ach.reward and ach.unlocked then
                graphics.setColor(1, 0.8, 0.2, 1)
                graphics.print("Reward: " .. ach.reward, 400, y + 50)
            end
        end

        y = y + itemHeight
    end

    self.maxScroll = math.max(0, #self.achievementsList * itemHeight - 500)
end

function CollectionUI:drawCollection(startY, category)
    local items = self.collectionData[category] or {}

    local y = startY - self.scrollOffset
    local itemHeight = 100
    local cols = 4
    local itemWidth = 280
    local spacing = 20

    graphics.setFont(self.smallFont)

    -- Display unlocked items
    local count = 0
    for i, itemId in ipairs(items) do
        local col = (count % cols)
        local row = math.floor(count / cols)

        local x = 50 + col * (itemWidth + spacing)
        local cardY = y + row * (itemHeight + spacing)

        if cardY > 150 and cardY < 700 then
            -- Card box
            graphics.setColor(0.2, 0.3, 0.4, 0.9)
            graphics.rectangle("fill", x, cardY, itemWidth, itemHeight)

            graphics.setColor(0.5, 0.7, 0.9, 1)
            graphics.rectangle("line", x, cardY, itemWidth, itemHeight)

            -- Item name
            graphics.setColor(1, 1, 1, 1)
            graphics.print(itemId, x + 10, cardY + 10)

            -- Try to load and show description
            local desc = self:getItemDescription(category, itemId)
            if desc then
                graphics.setColor(0.8, 0.8, 0.8, 1)
                graphics.print(desc, x + 10, cardY + 35)
            end
        end

        count = count + 1
    end

    -- Show count
    graphics.setFont(self.font)
    graphics.setColor(1, 1, 1, 1)
    local totalPossible = self:getTotalInCategory(category)
    graphics.print(string.format("Unlocked: %d/%d", #items, totalPossible), 50, startY - 40)

    self.maxScroll = math.max(0, math.ceil(#items / cols) * (itemHeight + spacing) - 500)
end

function CollectionUI:getItemDescription(category, itemId)
    -- Try to load from JSON
    local path = nil
    if category == "jokers" then
        path = "content/data/jokers/" .. itemId .. ".json"
    elseif category == "planets" then
        path = "content/data/enhancements/" .. itemId .. ".json"
    elseif category == "warps" then
        path = "content/data/warps/" .. itemId .. ".json"
    elseif category == "imprints" then
        path = "content/data/imprints/" .. itemId .. ".json"
    elseif category == "sculptors" then
        path = "content/data/spectrals/" .. itemId .. ".json"
    end

    if path then
        local data = files and files.loadJSON and files.loadJSON(path) or nil
        if data and data.description then
            return data.description
        elseif data and data.desc then
            return data.desc
        end
    end

    return nil
end

function CollectionUI:getTotalInCategory(category)
    if category == "jokers" then
        return 40
    elseif category == "planets" then
        return 21
    elseif category == "warps" then
        return 15
    elseif category == "imprints" then
        return 25
    elseif category == "sculptors" then
        return 8
    end
    return 0
end

return CollectionUI
