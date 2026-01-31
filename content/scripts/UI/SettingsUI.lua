-- SettingsUI.lua
-- Settings menu showcasing Phase 1 features

local Theme = require("UI.Theme")
local UIScale = require("UI.UIScale")
local UIButton = require("UI.elements.UIButton")
local UILabel = require("UI.elements.UILabel")
local UIPanel = require("UI.elements.UIPanel")

SettingsUI = class()

function SettingsUI:init(font, layout)
    self.font = font
    self.layout = layout
    self.active = false
    
    -- Create main panel
    local winW, winH = graphics.getWindowSize()
    local panelW, panelH = 600, 700
    self.panel = UIPanel((winW - panelW) / 2, (winH - panelH) / 2, panelW, panelH, {
        style = "raised",
        padding = Theme.get("sizes.paddingLarge")
    })
    
    -- UI elements
    self.buttons = {}
    self.labels = {}
    
    -- Current settings
    self.currentTheme = Theme.current
    self.currentScale = UIScale.get()
    
    self:createUI()
end

function SettingsUI:createUI()
    local panelArea = self.panel:getContentArea()
    local yOffset = panelArea.y + 10
    local xLeft = panelArea.x
    local buttonWidth = 180
    local buttonHeight = Theme.get("sizes.buttonHeight")
    local spacing = 15
    
    -- Title
    local titleLabel = UILabel(nil, "Settings", self.font, Theme.get("colors.text"))
    titleLabel.x = panelArea.x
    titleLabel.y = yOffset
    titleLabel.width = panelArea.width
    titleLabel.height = 40
    titleLabel.align = "center"
    titleLabel.valign = "middle"
    table.insert(self.labels, titleLabel)
    yOffset = yOffset + 60
    
    -- === THEME SECTION ===
    local themeSectionLabel = UILabel(nil, "Visual Theme", self.font, Theme.get("colors.text"))
    themeSectionLabel.x = xLeft
    themeSectionLabel.y = yOffset
    themeSectionLabel.width = panelArea.width
    themeSectionLabel.height = 30
    table.insert(self.labels, themeSectionLabel)
    yOffset = yOffset + 35
    
    -- Current theme display
    self.currentThemeLabel = UILabel(nil, "Current: " .. self.currentTheme, self.font, Theme.get("colors.textMuted"))
    self.currentThemeLabel.x = xLeft
    self.currentThemeLabel.y = yOffset
    self.currentThemeLabel.width = panelArea.width
    self.currentThemeLabel.height = 25
    table.insert(self.labels, self.currentThemeLabel)
    yOffset = yOffset + 30
    
    -- Theme buttons
    local themeButtonX = xLeft + 10
    local defaultThemeBtn = UIButton(nil, "Default Theme", self.font, function()
        self:setTheme("default")
    end, "primary")
    defaultThemeBtn:setPos(themeButtonX, yOffset)
    defaultThemeBtn:setSize(buttonWidth, buttonHeight)
    table.insert(self.buttons, defaultThemeBtn)
    
    local colorblindBtn = UIButton(nil, "Colorblind Mode", self.font, function()
        self:setTheme("deuteranopia")
    end, "success")
    colorblindBtn:setPos(themeButtonX + buttonWidth + 15, yOffset)
    colorblindBtn:setSize(buttonWidth, buttonHeight)
    table.insert(self.buttons, colorblindBtn)
    
    yOffset = yOffset + buttonHeight + spacing + 20
    
    -- === UI SCALE SECTION ===
    local scaleSectionLabel = UILabel(nil, "UI Scale", self.font, Theme.get("colors.text"))
    scaleSectionLabel.x = xLeft
    scaleSectionLabel.y = yOffset
    scaleSectionLabel.width = panelArea.width
    scaleSectionLabel.height = 30
    table.insert(self.labels, scaleSectionLabel)
    yOffset = yOffset + 35
    
    -- Current scale display
    self.currentScaleLabel = UILabel(nil, string.format("Current: %.0f%%", self.currentScale * 100), self.font, Theme.get("colors.textMuted"))
    self.currentScaleLabel.x = xLeft
    self.currentScaleLabel.y = yOffset
    self.currentScaleLabel.width = panelArea.width
    self.currentScaleLabel.height = 25
    table.insert(self.labels, self.currentScaleLabel)
    yOffset = yOffset + 30
    
    -- Scale preset buttons
    local scaleButtonWidth = 110
    local scaleButtonX = xLeft + 10
    
    -- First row
    local scale75Btn = UIButton(nil, "75%", self.font, function()
        self:setScale(UIScale.PRESETS.SMALL)
    end, "secondary")
    scale75Btn:setPos(scaleButtonX, yOffset)
    scale75Btn:setSize(scaleButtonWidth, buttonHeight)
    table.insert(self.buttons, scale75Btn)
    
    local scale100Btn = UIButton(nil, "100%", self.font, function()
        self:setScale(UIScale.PRESETS.NORMAL)
    end, "primary")
    scale100Btn:setPos(scaleButtonX + scaleButtonWidth + 10, yOffset)
    scale100Btn:setSize(scaleButtonWidth, buttonHeight)
    table.insert(self.buttons, scale100Btn)
    
    local scale125Btn = UIButton(nil, "125%", self.font, function()
        self:setScale(UIScale.PRESETS.LARGE)
    end, "secondary")
    scale125Btn:setPos(scaleButtonX + (scaleButtonWidth + 10) * 2, yOffset)
    scale125Btn:setSize(scaleButtonWidth, buttonHeight)
    table.insert(self.buttons, scale125Btn)
    
    yOffset = yOffset + buttonHeight + 10
    
    -- Second row
    local scale150Btn = UIButton(nil, "150%", self.font, function()
        self:setScale(UIScale.PRESETS.HUGE)
    end, "secondary")
    scale150Btn:setPos(scaleButtonX, yOffset)
    scale150Btn:setSize(scaleButtonWidth, buttonHeight)
    table.insert(self.buttons, scale150Btn)
    
    local autoScaleBtn = UIButton(nil, "Auto", self.font, function()
        UIScale.auto()
        self:updateScaleDisplay()
    end, "info")
    autoScaleBtn:setPos(scaleButtonX + scaleButtonWidth + 10, yOffset)
    autoScaleBtn:setSize(scaleButtonWidth, buttonHeight)
    table.insert(self.buttons, autoScaleBtn)
    
    yOffset = yOffset + buttonHeight + spacing + 20
    
    -- === CONTROLLER INFO SECTION ===
    local controllerSectionLabel = UILabel(nil, "Controller", self.font, Theme.get("colors.text"))
    controllerSectionLabel.x = xLeft
    controllerSectionLabel.y = yOffset
    controllerSectionLabel.width = panelArea.width
    controllerSectionLabel.height = 30
    table.insert(self.labels, controllerSectionLabel)
    yOffset = yOffset + 35
    
    -- Controller status
    self.controllerStatusLabel = UILabel(nil, self:getControllerStatus(), self.font, Theme.get("colors.textMuted"))
    self.controllerStatusLabel.x = xLeft
    self.controllerStatusLabel.y = yOffset
    self.controllerStatusLabel.width = panelArea.width
    self.controllerStatusLabel.height = 50
    self.controllerStatusLabel.wrap = true
    table.insert(self.labels, self.controllerStatusLabel)
    yOffset = yOffset + 60
    
    -- === CLOSE BUTTON ===
    yOffset = yOffset + 20
    local closeBtn = UIButton(nil, "Close", self.font, function()
        self:close()
    end, "danger")
    closeBtn:setPos(panelArea.x + (panelArea.width - buttonWidth) / 2, yOffset)
    closeBtn:setSize(buttonWidth, buttonHeight)
    table.insert(self.buttons, closeBtn)
end

function SettingsUI:setTheme(themeName)
    Theme.setTheme(themeName)
    self.currentTheme = themeName
    self.currentThemeLabel:setText("Current: " .. themeName)
    log.info("Theme changed to: " .. themeName)
end

function SettingsUI:setScale(scale)
    UIScale.set(scale)
    self.currentScale = scale
    self:updateScaleDisplay()
    log.info(string.format("UI scale set to: %.0f%%", scale * 100))
end

function SettingsUI:updateScaleDisplay()
    self.currentScale = UIScale.get()
    self.currentScaleLabel:setText(string.format("Current: %.0f%%", self.currentScale * 100))
end

function SettingsUI:getControllerStatus()
    if inputmgr.isGamepadConnected() then
        local name = inputmgr.getGamepadName()
        local device = inputmgr.isGamepad() and "Active" or "Connected (not active)"
        return "Gamepad: " .. name .. "\nStatus: " .. device
    else
        return "No gamepad detected\nUsing keyboard/mouse"
    end
end

function SettingsUI:open()
    self.active = true
    -- Update displays
    self:updateScaleDisplay()
    self.currentThemeLabel:setText("Current: " .. Theme.current)
    self.controllerStatusLabel:setText(self:getControllerStatus())
    log.info("Settings menu opened")
end

function SettingsUI:close()
    self.active = false
    log.info("Settings menu closed")
end

function SettingsUI:update(dt, mx, my, clicked)
    if not self.active then return false end
    
    -- Update controller status periodically
    self.controllerStatusLabel:setText(self:getControllerStatus())
    
    -- Update all buttons
    for _, button in ipairs(self.buttons) do
        button:update(dt, mx, my, clicked)
    end
    
    -- Check for ESC to close
    if inputmgr.isActionJustPressed("cancel") or inputmgr.isActionJustPressed("open_menu") then
        self:close()
        return { action = "close" }
    end
    
    return false
end

function SettingsUI:draw()
    if not self.active then return end
    
    local winW, winH = graphics.getWindowSize()
    
    -- Draw overlay
    graphics.drawRect(0, 0, winW, winH, Theme.get("colors.overlay"), true)
    
    -- Draw panel
    self.panel:draw()
    
    -- Draw labels
    for _, label in ipairs(self.labels) do
        label:draw()
    end
    
    -- Draw buttons
    for _, button in ipairs(self.buttons) do
        button:draw()
    end
    
    -- Draw hint text at bottom
    local hintText = "Press ESC or B (controller) to close"
    local hintW = graphics.getTextSize(self.font, hintText)
    local hintX = (winW - hintW) / 2
    local hintY = winH - 40
    graphics.print(self.font, hintText, hintX, hintY, Theme.get("colors.textMuted"))
end

return SettingsUI
