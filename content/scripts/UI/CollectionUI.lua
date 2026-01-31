-- CollectionUI.lua
-- Collection browser and achievement viewer

local Theme = require("UI.Theme")

local CollectionUI = class()

function CollectionUI:init(font, smallFont, layout)
    self.font = font
    self.smallFont = smallFont
    self.layout = layout -- Store layout instance
    self.visible = false

    -- Tabs
    self.currentTab = "achievements" -- "achievements", "jokers", "planets", "warps", "imprints", "sculptors"
    self.tabs = { "achievements", "jokers", "planets", "warps", "imprints", "sculptors" }
    self.selectedTabIndex = 1

    -- Scroll state
    self.scrollOffset = 0
    self.maxScroll = 0

    -- Cache
    self.achievementsList = {}
    self.collectionData = {}
    
    -- Cache theme colors for performance
    self.colors = {
        overlay = Theme.get("colors.overlay"),
        background = Theme.get("colors.backgroundDark"),
        panelBg = Theme.get("colors.panelBg"),
        panelBgHover = Theme.get("colors.panelBgHover"),
        text = Theme.get("colors.text"),
        textMuted = Theme.get("colors.textMuted"),
        primary = Theme.get("colors.primary"),
        success = Theme.get("colors.success"),
        successLight = Theme.lighten(Theme.get("colors.success"), 0.2),
        gold = Theme.get("colors.gold"),
        border = Theme.get("colors.border"),
        borderLight = Theme.get("colors.borderLight")
    }
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

    local mx, my = inputmgr.getCursor()
    local clicked = inputmgr.isActionJustPressed("confirm")

    -- Tab switching with mouse
    local tabY = 100
    local tabX = 50
    local tabWidth = 150
    local tabHeight = 40

    for i, tab in ipairs(self.tabs) do
        local tx = tabX + (i - 1) * (tabWidth + 10)
        if mx >= tx and mx <= tx + tabWidth and my >= tabY and my <= tabY + tabHeight then
            if clicked then
                self.currentTab = tab
                self.selectedTabIndex = i
                self.scrollOffset = 0
            end
        end
    end

    -- Tab switching with controller (LB/RB or Tab)
    if inputmgr.isActionJustPressed("tab_next") then
        self.selectedTabIndex = self.selectedTabIndex + 1
        if self.selectedTabIndex > #self.tabs then
            self.selectedTabIndex = 1
        end
        self.currentTab = self.tabs[self.selectedTabIndex]
        self.scrollOffset = 0
    elseif inputmgr.isActionJustPressed("tab_previous") then
        self.selectedTabIndex = self.selectedTabIndex - 1
        if self.selectedTabIndex < 1 then
            self.selectedTabIndex = #self.tabs
        end
        self.currentTab = self.tabs[self.selectedTabIndex]
        self.scrollOffset = 0
    end

    -- Scrolling with controller or keyboard
    local scrollSpeed = 30
    if inputmgr.isActionPressed("navigate_up") then
        self.scrollOffset = math.max(0, self.scrollOffset - scrollSpeed)
    elseif inputmgr.isActionPressed("navigate_down") then
        self.scrollOffset = math.min(self.maxScroll, self.scrollOffset + scrollSpeed)
    end

    -- Close button
    if inputmgr.isActionJustPressed("cancel") or inputmgr.isActionJustPressed("open_menu") then
        self:hide()
        return "close"
    end
end

function CollectionUI:draw()
    if not self.visible then return end

    local winW, winH = graphics.getWindowSize()

    -- Dim background
    graphics.drawRect(0, 0, winW, winH, self.colors.overlay, true)

    -- Title
    graphics.print(self.font, "COLLECTION", 50, 30, self.colors.text)

    -- Progress summary
    if MagicHandsAchievements then
        local progress = MagicHandsAchievements:getProgress()
        local unlocked = MagicHandsAchievements:countUnlocked()
        local total = MagicHandsAchievements:count()

        graphics.print(self.smallFont, string.format("Achievements: %d/%d (%.1f%%)", unlocked, total, progress), 500, 40, self.colors.textMuted)
    end

    if UnlockSystem then
        local totalUnlocked = UnlockSystem:getTotalUnlocked()
        graphics.print(self.smallFont, string.format("Cards Unlocked: %d/121", totalUnlocked), 800, 40, self.colors.gold)
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

    -- Close hint (show controller prompts if gamepad active)
    local hintText
    if inputmgr.isGamepad() then
        hintText = "[B] Close   [LB/RB] Switch Tabs   [D-Pad] Scroll"
    else
        hintText = "[ESC] Close   [Tab/Shift+Tab] Switch Tabs   [Arrow Keys] Scroll"
    end
    graphics.print(self.smallFont, hintText, 50, winH - 40, self.colors.textMuted)
end

function CollectionUI:drawTabs()
    local tabY = 100
    local tabX = 50
    local tabWidth = 150
    local tabHeight = 40

    for i, tab in ipairs(self.tabs) do
        local tx = tabX + (i - 1) * (tabWidth + 10)

        -- Tab background
        local bgColor
        if tab == self.currentTab then
            bgColor = self.colors.primary
        else
            bgColor = self.colors.background
        end
        graphics.drawRect(tx, tabY, tabWidth, tabHeight, bgColor, true)

        -- Tab border
        local borderColor = tab == self.currentTab and self.colors.borderLight or self.colors.border
        graphics.drawRect(tx, tabY, tabWidth, tabHeight, borderColor, false)

        -- Tab text
        local label = tab:gsub("^%l", string.upper)
        local textColor = tab == self.currentTab and self.colors.text or self.colors.textMuted
        graphics.print(self.smallFont, label, tx + 10, tabY + 12, textColor)
    end
end

function CollectionUI:drawAchievements(startY)
    local y = startY - self.scrollOffset
    local itemHeight = 80

    for i, ach in ipairs(self.achievementsList) do
        if y > 150 and y < 700 then
            -- Achievement box
            local bgColor = ach.unlocked and Theme.withAlpha(self.colors.success, 0.2) or self.colors.panelBg
            graphics.drawRect(50, y, 1180, itemHeight - 10, bgColor, true)

            -- Border
            local borderColor = ach.unlocked and self.colors.successLight or self.colors.border
            graphics.drawRect(50, y, 1180, itemHeight - 10, borderColor, false)

            -- Icon area (placeholder)
            graphics.drawRect(60, y + 10, 50, 50, self.colors.background, true)

            -- Achievement name
            local prefix = ach.unlocked and "✓ " or "🔒 "
            graphics.print(self.font, prefix .. ach.name, 120, y + 5, self.colors.text)

            -- Description
            graphics.print(self.smallFont, ach.description, 120, y + 30, self.colors.textMuted)

            -- Category badge
            graphics.print(self.smallFont, "[" .. ach.category .. "]", 120, y + 50, self.colors.primary)

            -- Reward
            if ach.reward and ach.unlocked then
                graphics.print(self.smallFont, "Reward: " .. ach.reward, 400, y + 50, self.colors.gold)
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

    -- Display unlocked items
    local count = 0
    for i, itemId in ipairs(items) do
        local col = (count % cols)
        local row = math.floor(count / cols)

        local x = 50 + col * (itemWidth + spacing)
        local cardY = y + row * (itemHeight + spacing)

        if cardY > 150 and cardY < 700 then
            -- Card box
            graphics.drawRect(x, cardY, itemWidth, itemHeight, self.colors.panelBg, true)
            graphics.drawRect(x, cardY, itemWidth, itemHeight, self.colors.primary, false)

            -- Item name
            graphics.print(self.smallFont, itemId, x + 10, cardY + 10, self.colors.text)

            -- Try to load and show description
            local desc = self:getItemDescription(category, itemId)
            if desc then
                graphics.print(self.smallFont, desc, x + 10, cardY + 35, self.colors.textMuted)
            end
        end

        count = count + 1
    end

    -- Show count
    local totalPossible = self:getTotalInCategory(category)
    graphics.print(self.font, string.format("Unlocked: %d/%d", #items, totalPossible), 50, startY - 40, self.colors.text)

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
    elseif string.find(itemId, "spectral_") then
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
