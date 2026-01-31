-- MenuScene.lua
-- Main Menu for Magic Hands

local Theme = require("UI.Theme")
local UIButton = require("UI.elements.UIButton")
local UILayout = require("UI.UILayout")
local SettingsUI = require("UI.SettingsUI")

MenuScene = class()

function MenuScene:enter()
    print("=== Entered Menu Scene ===")
    
    -- Store reference resolution (what we design for)
    self.referenceWidth = 1280
    self.referenceHeight = 720
    
    -- Load fonts
    self.titleFont = graphics.loadFont("content/fonts/font.ttf", 72)
    self.font = graphics.loadFont("content/fonts/font.ttf", 32)
    self.smallFont = graphics.loadFont("content/fonts/font.ttf", 18)
    
    -- Debug: Check if fonts loaded
    print("MenuScene fonts loaded:")
    print("  titleFont: " .. tostring(self.titleFont))
    print("  font: " .. tostring(self.font))
    print("  smallFont: " .. tostring(self.smallFont))
    
    -- Get screen size
    local winW, winH = graphics.getWindowSize()
    
    -- Calculate scale factor (use minimum to maintain aspect ratio)
    self.uiScale = math.min(winW / self.referenceWidth, winH / self.referenceHeight)
    print(string.format("UI Scale: %.2f (screen: %dx%d)", self.uiScale, winW, winH))
    
    -- Initialize UI Layout
    self.layout = UILayout(winW, winH)
    
    -- Cache theme colors
    self.colors = {
        background = Theme.get("colors.panelBgActive"),  -- Use darkest panel color
        title = Theme.get("colors.primary"),
        subtitle = Theme.get("colors.textMuted"),
        version = Theme.get("colors.textDisabled")
    }
    
    -- Check if save exists
    self.hasSaveData = self:checkSaveData()
    
    -- Create buttons using scaled dimensions
    self:createButtons()
    
    -- Version info
    self.version = "v0.1.0"
    
    -- Create Settings UI
    self.settingsUI = SettingsUI(self.font, self.layout)
    self.showSettings = false
    self.settingsWasOpen = false  -- Track previous frame state
    
    print("Menu Scene initialized")
end

function MenuScene:exit()
    print("Exited Menu Scene")
end

function MenuScene:scale(value)
    return value * self.uiScale
end

function MenuScene:createButtons()
    local winW, winH = graphics.getWindowSize()
    
    -- Base dimensions at 1280x720
    local baseButtonWidth = 300
    local baseButtonHeight = 70
    local baseButtonSpacing = 20
    
    -- Scale dimensions (not positions)
    local buttonWidth = self:scale(baseButtonWidth)
    local buttonHeight = self:scale(baseButtonHeight)
    local buttonSpacing = self:scale(baseButtonSpacing)
    
    -- Calculate total height of all buttons
    local totalButtonHeight = buttonHeight * 4 + buttonSpacing * 3
    
    -- Center buttons vertically in the screen
    local startY = (winH - totalButtonHeight) / 2
    
    -- Calculate button positions (centered horizontally)
    local centerX = (winW - buttonWidth) / 2
    
    print(string.format("Creating buttons: winSize=%dx%d, scale=%.2f", winW, winH, self.uiScale))
    print(string.format("  Button size=%.0fx%.0f, spacing=%.0f, startY=%.0f (centered)", 
        buttonWidth, buttonHeight, buttonSpacing, startY))
    
    -- Start New Game Button
    self.startButton = UIButton(nil, "START NEW GAME", self.font, function()
        self:startNewGame()
    end, "success")
    self.startButton:setPos(centerX, startY)
    self.startButton:setSize(buttonWidth, buttonHeight)
    
    -- Continue Game Button
    self.continueButton = UIButton(nil, "CONTINUE", self.font, function()
        self:continueGame()
    end, "primary")
    self.continueButton:setPos(centerX, startY + buttonHeight + buttonSpacing)
    self.continueButton:setSize(buttonWidth, buttonHeight)
    
    if not self.hasSaveData then
        self.continueButton:setDisabled(true)
    end
    
    -- Settings Button
    self.settingsButton = UIButton(nil, "SETTINGS", self.font, function()
        self:openSettings()
    end, "secondary")
    self.settingsButton:setPos(centerX, startY + (buttonHeight + buttonSpacing) * 2)
    self.settingsButton:setSize(buttonWidth, buttonHeight)
    
    -- Exit Button
    self.exitButton = UIButton(nil, "EXIT", self.font, function()
        self:exitGame()
    end, "danger")
    self.exitButton:setPos(centerX, startY + (buttonHeight + buttonSpacing) * 3)
    self.exitButton:setSize(buttonWidth, buttonHeight)
    
    -- Store all buttons for easy iteration
    self.buttons = {
        self.startButton,
        self.continueButton,
        self.settingsButton,
        self.exitButton
    }
    
    -- Controller navigation
    self.selectedIndex = self.hasSaveData and 2 or 1
    if not self.hasSaveData then
        self.selectedIndex = 1
    end
end

function MenuScene:checkSaveData()
    -- Check if CampaignState has save data
    if CampaignState and CampaignState.currentBlind and CampaignState.currentBlind > 0 then
        return true
    end
    
    -- TODO: Check for actual save file when save/load system is implemented
    return false
end

function MenuScene:startNewGame()
    print("Starting new game...")
    
    -- Reset CampaignState
    if CampaignState then
        CampaignState:reset()
    end
    
    -- Transition to GameScene
    SceneManager.switch("GameScene")
end

function MenuScene:continueGame()
    if not self.hasSaveData then
        print("No save data to continue")
        return
    end
    
    print("Continuing game...")
    
    -- Load save data (if save/load system exists)
    -- For now, just transition to GameScene with existing CampaignState
    SceneManager.switch("GameScene")
end

function MenuScene:openSettings()
    print("Opening settings menu...")
    self.showSettings = true
    self.settingsJustOpened = true  -- Flag to skip update on open frame
    self.settingsUI:open()
end

function MenuScene:exitGame()
    print("Exit game - closing application")
    -- Request application exit
    -- Note: May need to add engine API for this
    os.exit()
end

function MenuScene:update(dt)
    -- Get input
    local mx, my = input.getMousePosition()
    local clicked = input.isMouseButtonPressed("left")
    
    -- Handle settings menu if open
    if self.showSettings then
        -- Don't update settings on the frame it just opened (prevent click propagation)
        if not self.settingsJustOpened then
            local result = self.settingsUI:update(dt, mx, my, clicked)
            if result and result.action == "close" then
                print("Settings closing - resetting menu button states")
                self.showSettings = false
                self.settingsUI:close()
                
                -- Consume the click to prevent it from triggering menu buttons
                clicked = false
                
                -- Force reset all button states
                for i, button in ipairs(self.buttons) do
                    button.wasClicked = false
                    button.isHoveredState = false
                end
                -- Don't return - update buttons with clicked=false to reset their state
            else
                return  -- Only return if settings is still open
            end
        else
            -- Skip update on open frame, but consume the click
            self.settingsJustOpened = false
            return  -- Block menu input
        end
    end
    
    -- Handle window resize
    local winW, winH = graphics.getWindowSize()
    if winW ~= self.layout.screenWidth or winH ~= self.layout.screenHeight then
        print(string.format("Window resized: %dx%d -> %dx%d", self.layout.screenWidth, self.layout.screenHeight, winW, winH))
        self.layout:updateScreenSize(winW, winH)
        
        -- Recalculate scale factor
        self.uiScale = math.min(winW / self.referenceWidth, winH / self.referenceHeight)
        print(string.format("New UI Scale: %.2f", self.uiScale))
        
        -- Recreate buttons with new scale
        self:createButtons()
    end
    
    -- Update all buttons
    for i, button in ipairs(self.buttons) do
        button:update(dt, mx, my, clicked)
    end
    
    -- Reset button states AFTER updating if settings just opened
    if self.showSettings and not self.settingsWasOpen then
        for i, button in ipairs(self.buttons) do
            button.wasClicked = false
            button.isHoveredState = false
        end
    end
    
    -- Track whether settings was open last frame
    self.settingsWasOpen = self.showSettings
    
    -- Controller navigation
    if inputmgr.isActionJustPressed("navigate_up") then
        self.selectedIndex = self.selectedIndex - 1
        if self.selectedIndex < 1 then
            self.selectedIndex = #self.buttons
        end
        
        -- Skip disabled buttons
        while self.buttons[self.selectedIndex].disabled do
            self.selectedIndex = self.selectedIndex - 1
            if self.selectedIndex < 1 then
                self.selectedIndex = #self.buttons
            end
        end
    elseif inputmgr.isActionJustPressed("navigate_down") then
        self.selectedIndex = self.selectedIndex + 1
        if self.selectedIndex > #self.buttons then
            self.selectedIndex = 1
        end
        
        -- Skip disabled buttons
        while self.buttons[self.selectedIndex].disabled do
            self.selectedIndex = self.selectedIndex + 1
            if self.selectedIndex > #self.buttons then
                self.selectedIndex = 1
            end
        end
    end
    
    -- Confirm with controller
    if inputmgr.isActionJustPressed("confirm") then
        local button = self.buttons[self.selectedIndex]
        if button and not button.disabled and button.onClick then
            button.onClick()
        end
    end
    
    -- Open settings with shortcut (ESC or Start button)
    if inputmgr.isActionJustPressed("open_settings") then
        self:openSettings()
    end
end

function MenuScene:draw()
    local winW, winH = graphics.getWindowSize()
    
    -- Debug: Print screen info once per second
    if not self.lastDebugTime then self.lastDebugTime = 0 end
    local currentTime = os.clock()
    if currentTime - self.lastDebugTime > 1.0 then
        print(string.format("DRAW: Window=%dx%d, Scale=%.2f, Buttons=%d", 
            winW, winH, self.uiScale, #self.buttons))
        if self.buttons[1] then
            print(string.format("  Button 1 pos: (%.0f, %.0f) size: %.0fx%.0f", 
                self.buttons[1].x, self.buttons[1].y, self.buttons[1].width, self.buttons[1].height))
        end
        self.lastDebugTime = currentTime
    end
    
    -- Draw background
    graphics.drawRect(0, 0, winW, winH, self.colors.background, true)
    
    -- Draw title (positioned relative to top, scaled spacing)
    if self.titleFont and self.titleFont ~= -1 then
        local titleText = "MAGIC HANDS"
        local titleW = graphics.getTextSize(self.titleFont, titleText)
        local titleX = (winW - titleW) / 2
        local titleY = winH * 0.15  -- 15% from top (relative positioning)
        
        -- Title shadow
        local shadowOffset = self:scale(4)
        graphics.print(self.titleFont, titleText, titleX + shadowOffset, titleY + shadowOffset, Theme.withAlpha(self.colors.background, 0.8))
        
        -- Title text
        graphics.print(self.titleFont, titleText, titleX, titleY, self.colors.title)
    end
    
    -- Subtitle (positioned relative to title, scaled spacing)
    if self.font and self.font ~= -1 then
        local subtitleText = "A Cribbage Roguelike"
        local subtitleW = graphics.getTextSize(self.font, subtitleText)
        local subtitleX = (winW - subtitleW) / 2
        local subtitleY = winH * 0.15 + self:scale(90)  -- Below title with scaled spacing
        graphics.print(self.font, subtitleText, subtitleX, subtitleY, self.colors.subtitle)
    end
    
    -- Draw buttons
    for i, button in ipairs(self.buttons) do
        button:draw()
        
        -- Draw selection indicator for controller
        if i == self.selectedIndex and inputmgr.isGamepad() then
            local borderColor = Theme.get("colors.warning")
            for j = 0, 2 do
                graphics.drawRect(button.x - j - 2, button.y - j - 2, 
                                button.width + (j + 2) * 2, button.height + (j + 2) * 2, 
                                borderColor, false)
            end
        end
    end
    
    -- Draw version info and controls hint (scaled)
    if self.smallFont and self.smallFont ~= -1 then
        local versionY = winH - self:scale(30)
        graphics.print(self.smallFont, self.version, self:scale(10), versionY, self.colors.version)
        
        -- Draw controls hint
        local hintText
        if inputmgr.isGamepad() then
            hintText = "[D-Pad] Navigate   [A] Select   [Start] Settings"
        else
            hintText = "Click to select • [↑↓] Navigate • [Enter] Confirm • [F1] Settings"
        end
        local hintW = graphics.getTextSize(self.smallFont, hintText)
        local hintY = winH - self:scale(30)
        graphics.print(self.smallFont, hintText, (winW - hintW) / 2, hintY, self.colors.subtitle)
    end
    
    -- Draw settings overlay if open
    if self.showSettings then
        self.settingsUI:draw()
    end
end

return MenuScene
