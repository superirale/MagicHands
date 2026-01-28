-- Test script to verify text centering in headers and buttons
-- This creates simple card headers and buttons to visualize the centered text

TestTextCentering = {}

function TestTextCentering.init()
    log.info("=== Text Centering Test ===")
    
    -- Load a font
    TestTextCentering.font = graphics.loadFont("content/fonts/Geist-Regular.ttf", 16)
    
    if not TestTextCentering.font or TestTextCentering.font < 0 then
        log.error("Failed to load font!")
        return
    end
    
    log.info("Font loaded successfully: " .. TestTextCentering.font)
    
    -- Test texts with different characteristics
    TestTextCentering.testTexts = {
        "CARD NAME",      -- All caps
        "The Joker",      -- Mixed case with descender
        "Typography",     -- Has descenders (p, y, g)
        "HELLO",          -- Short all caps
        "Mighty King"     -- Mixed with ascenders
    }
    
    -- Button test texts
    TestTextCentering.buttonTexts = {
        "Click Me",
        "Next Round >",
        "Reroll Shop",
        "BUY"
    }
    
    -- Label test (horizontal alignment)
    TestTextCentering.labelTests = {
        {text = "Left Aligned", align = "left", valign = "middle"},
        {text = "Center Aligned", align = "center", valign = "middle"},
        {text = "Right Aligned", align = "right", valign = "middle"}
    }
    
    -- Label vertical alignment test
    TestTextCentering.vlabelTests = {
        {text = "Top Aligned", align = "center", valign = "top"},
        {text = "Middle Aligned", align = "center", valign = "middle"},
        {text = "Bottom Aligned", align = "center", valign = "bottom"}
    }
    
    log.info("Test initialized with " .. #TestTextCentering.testTexts .. " test cases")
end

function TestTextCentering.draw()
    if not TestTextCentering.font then return end
    
    local screenW = Window.getWidth()
    local screenH = Window.getHeight()
    
    -- Background
    graphics.drawRect(0, 0, screenW, screenH, {r=0.1, g=0.1, b=0.12, a=1}, true)
    
    -- Title
    graphics.print(TestTextCentering.font, "Text Centering Test - Press ESC to exit", 20, 20, {r=1, g=1, b=1, a=1})
    
    -- Draw test headers
    local cardWidth = 220
    local headerHeight = 50
    local startX = 50
    local startY = 80
    local spacing = 20
    
    for i, text in ipairs(TestTextCentering.testTexts) do
        local x = startX
        local y = startY + (i - 1) * (headerHeight + spacing)
        local color = TestTextCentering.colors[i]
        
        -- Draw header rectangle
        graphics.drawRect(x, y, cardWidth, headerHeight, color, true)
        
        -- Get text size with baseline offset
        local textW, textH, baselineOffset = graphics.getTextSize(TestTextCentering.font, text)
        
        -- Center text horizontally
        local tx = x + (cardWidth - textW) / 2
        
        -- Center text vertically using baseline offset
        local ty = y + (headerHeight - textH) / 2 + baselineOffset
        
        -- Draw text with shadow
        graphics.print(TestTextCentering.font, text, tx + 1, ty + 1, {r=0, g=0, b=0, a=0.5})
        graphics.print(TestTextCentering.font, text, tx, ty, {r=1, g=1, b=1, a=1})
        
        -- Draw debug info
        local debugX = x + cardWidth + 30
        local debugText = string.format("w:%.1f h:%.1f bl:%.1f", textW, textH, baselineOffset)
        graphics.print(TestTextCentering.font, debugText, debugX, y + headerHeight/2 - 8, {r=0.7, g=0.7, b=0.7, a=1})
        
        -- Draw center line for visual reference (horizontal line through middle of header)
        local centerY = y + headerHeight / 2
        graphics.drawRect(x, centerY, cardWidth, 1, {r=1, g=1, b=0, a=0.5}, true)
    end
    
    -- Draw button tests (right side)
    local buttonWidth = 200
    local buttonHeight = 60
    local btnStartX = startX + cardWidth + 300
    local btnStartY = startY
    
    -- Section title
    graphics.print(TestTextCentering.font, "Button Centering Test", btnStartX, btnStartY - 30, {r=1, g=1, b=1, a=1})
    
    for i, text in ipairs(TestTextCentering.buttonTexts) do
        local x = btnStartX
        local y = btnStartY + (i - 1) * (buttonHeight + spacing)
        local bgColor = {r=0.3, g=0.3, b=0.3, a=1}
        
        -- Draw button background
        graphics.drawRect(x, y, buttonWidth, buttonHeight, bgColor, true)
        
        -- Draw button border
        graphics.drawRect(x, y, buttonWidth, buttonHeight, {r=1, g=1, b=1, a=0.5}, true)
        
        -- Get text size with baseline offset
        local textW, textH, baselineOffset = graphics.getTextSize(TestTextCentering.font, text)
        
        -- Center text (same as UIButton.lua does now)
        local tx = x + (buttonWidth - textW) / 2
        local ty = y + (buttonHeight - textH) / 2 + baselineOffset
        
        -- Draw text
        graphics.print(TestTextCentering.font, text, tx, ty, {r=1, g=1, b=1, a=1})
        
        -- Draw center line for visual reference (horizontal line through middle)
        local centerY = y + buttonHeight / 2
        graphics.drawRect(x, centerY, buttonWidth, 1, {r=1, g=1, b=0, a=0.5}, true)
        
        -- Draw debug info
        local debugText = string.format("w:%.1f h:%.1f bl:%.1f", textW, textH, baselineOffset)
        graphics.print(TestTextCentering.font, debugText, x + buttonWidth + 10, y + buttonHeight/2 - 8, {r=0.7, g=0.7, b=0.7, a=1})
    end
    
    -- Draw label tests (bottom section)
    local labelY = math.max(startY + #TestTextCentering.testTexts * (headerHeight + spacing),
                            btnStartY + #TestTextCentering.buttonTexts * (buttonHeight + spacing)) + 60
    
    -- Section title
    graphics.print(TestTextCentering.font, "Label Alignment Test", startX, labelY - 30, {r=1, g=1, b=1, a=1})
    
    local labelWidth = 300
    local labelHeight = 40
    
    for i, labelData in ipairs(TestTextCentering.labelTests) do
        local x = startX
        local y = labelY + (i - 1) * (labelHeight + 15)
        local bgColor = {r=0.2, g=0.2, b=0.25, a=1}
        
        -- Draw label background
        graphics.drawRect(x, y, labelWidth, labelHeight, bgColor, true)
        
        -- Draw label border
        graphics.drawRect(x, y, labelWidth, labelHeight, {r=1, g=1, b=1, a=0.3}, true)
        
        -- Get text size
        local textW, textH, baselineOffset = graphics.getTextSize(TestTextCentering.font, labelData.text)
        
        -- Calculate position based on alignment (same as UILabel.lua)
        local tx = x
        if labelData.align == "center" then
            tx = x + (labelWidth - textW) / 2
        elseif labelData.align == "right" then
            tx = x + labelWidth - textW
        end
        
        -- Center vertically
        local ty = y + (labelHeight - textH) / 2 + baselineOffset
        
        -- Draw text
        graphics.print(TestTextCentering.font, labelData.text, tx, ty, {r=1, g=1, b=1, a=1})
        
        -- Draw vertical center line
        local centerY = y + labelHeight / 2
        graphics.drawRect(x, centerY, labelWidth, 1, {r=1, g=1, b=0, a=0.3}, true)
        
        -- Draw alignment markers (vertical lines)
        if labelData.align == "left" then
            graphics.drawRect(x, y, 2, labelHeight, {r=0, g=1, b=0, a=0.5}, true)
        elseif labelData.align == "center" then
            local centerX = x + labelWidth / 2
            graphics.drawRect(centerX, y, 2, labelHeight, {r=0, g=1, b=1, a=0.5}, true)
        elseif labelData.align == "right" then
            graphics.drawRect(x + labelWidth - 2, y, 2, labelHeight, {r=1, g=0, b=0, a=0.5}, true)
        end
    end
    
    -- Draw vertical alignment tests
    local vlabelY = labelY + #TestTextCentering.labelTests * (labelHeight + 15) + 60
    local vlabelX = startX + 400
    
    -- Section title
    graphics.print(TestTextCentering.font, "Vertical Alignment Test", vlabelX, vlabelY - 30, {r=1, g=1, b=1, a=1})
    
    local vlabelWidth = 250
    local vlabelHeight = 80  -- Taller to show vertical alignment better
    
    for i, labelData in ipairs(TestTextCentering.vlabelTests) do
        local x = vlabelX
        local y = vlabelY + (i - 1) * (vlabelHeight + 15)
        local bgColor = {r=0.2, g=0.2, b=0.25, a=1}
        
        -- Draw label background
        graphics.drawRect(x, y, vlabelWidth, vlabelHeight, bgColor, true)
        
        -- Draw label border
        graphics.drawRect(x, y, vlabelWidth, vlabelHeight, {r=1, g=1, b=1, a=0.3}, true)
        
        -- Get text size
        local textW, textH, baselineOffset = graphics.getTextSize(TestTextCentering.font, labelData.text)
        
        -- Calculate horizontal position (centered)
        local tx = x + (vlabelWidth - textW) / 2
        
        -- Calculate vertical position based on valign (same as UILabel.lua)
        local ty = y
        if labelData.valign == "middle" then
            ty = y + (vlabelHeight - textH) / 2 + baselineOffset
        elseif labelData.valign == "top" then
            ty = y + baselineOffset
        elseif labelData.valign == "bottom" then
            ty = y + vlabelHeight - textH + baselineOffset
        end
        
        -- Draw text
        graphics.print(TestTextCentering.font, labelData.text, tx, ty, {r=1, g=1, b=1, a=1})
        
        -- Draw horizontal reference lines
        if labelData.valign == "top" then
            -- Top line (green)
            graphics.drawRect(x, y, vlabelWidth, 2, {r=0, g=1, b=0, a=0.5}, true)
        elseif labelData.valign == "middle" then
            -- Middle line (cyan)
            local centerY = y + vlabelHeight / 2
            graphics.drawRect(x, centerY, vlabelWidth, 2, {r=0, g=1, b=1, a=0.5}, true)
        elseif labelData.valign == "bottom" then
            -- Bottom line (red)
            graphics.drawRect(x, y + vlabelHeight - 2, vlabelWidth, 2, {r=1, g=0, b=0, a=0.5}, true)
        end
    end
    
    -- Instructions
    local instrY = math.max(labelY + #TestTextCentering.labelTests * (labelHeight + 15),
                            vlabelY + #TestTextCentering.vlabelTests * (vlabelHeight + 15)) + 30
    graphics.print(TestTextCentering.font, "Yellow line = visual center | Colored lines = alignment reference", 50, instrY, {r=1, g=1, b=0.7, a=1})
    graphics.print(TestTextCentering.font, "Green = top, Cyan = middle, Red = bottom | All text uses baseline offset for perfect positioning", 50, instrY + 25, {r=1, g=1, b=0.7, a=1})
end

function TestTextCentering.update(dt)
    -- Exit on ESC
    if input.isPressed("escape") then
        log.info("Exiting text centering test")
        os.exit(0)
    end
end

-- Initialize and set up game loop
TestTextCentering.init()

function love_update(dt)
    TestTextCentering.update(dt)
end

function love_draw()
    TestTextCentering.draw()
end
