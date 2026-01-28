-- Test script to verify text centering in headers
-- This creates a simple card-like header to visualize the centered text

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
    
    TestTextCentering.colors = {
        { r = 0.4, g = 0.6, b = 0.8, a = 1 }, -- Blue
        { r = 0.2, g = 0.7, b = 0.4, a = 1 }, -- Green
        { r = 0.8, g = 0.3, b = 0.3, a = 1 }, -- Red
        { r = 0.9, g = 0.8, b = 0.2, a = 1 }, -- Gold
        { r = 0.5, g = 0.4, b = 0.8, a = 1 }, -- Purple
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
    
    -- Instructions
    local instrY = startY + #TestTextCentering.testTexts * (headerHeight + spacing) + 20
    graphics.print(TestTextCentering.font, "Yellow line = visual center of header", 50, instrY, {r=1, g=1, b=0.7, a=1})
    graphics.print(TestTextCentering.font, "Text should be centered around the yellow line", 50, instrY + 25, {r=1, g=1, b=0.7, a=1})
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
