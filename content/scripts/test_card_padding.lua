-- Test script to demonstrate UICard padding functionality

local UICard = require("UI.elements.UICard")

TestCardPadding = {}

function TestCardPadding.init()
    log.info("=== UICard Padding Test ===")
    
    -- Load font
    TestCardPadding.font = graphics.loadFont("content/fonts/Geist-Regular.ttf", 16)
    
    if not TestCardPadding.font or TestCardPadding.font < 0 then
        log.error("Failed to load font!")
        return
    end
    
    -- Sample joker data
    local jokerData1 = {
        name = "The Fool",
        desc = "This is a short description that fits easily within the card.",
        rarity = "common",
        price = 50
    }
    
    local jokerData2 = {
        name = "Lucky Seven",
        desc = "This is a much longer description that will wrap across multiple lines to demonstrate the padding and line spacing functionality of the card component.",
        rarity = "rare",
        price = 150
    }
    
    local jokerData3 = {
        name = "Golden King",
        desc = "Medium length description with custom padding settings to show how different padding values affect the layout and readability.",
        rarity = "legendary",
        price = 300
    }
    
    -- Create cards with different padding settings
    TestCardPadding.cards = {}
    
    -- Card 1: Default padding
    local card1 = UICard(nil, jokerData1, TestCardPadding.font, function() log.info("Card 1 clicked") end)
    card1.x = 50
    card1.y = 100
    table.insert(TestCardPadding.cards, {card = card1, label = "Default Padding"})
    
    -- Card 2: Tight padding
    local card2 = UICard(nil, jokerData2, TestCardPadding.font, function() log.info("Card 2 clicked") end)
    card2.x = 300
    card2.y = 100
    card2:setPadding(10, 5, 5, 5, 18)  -- Minimal padding
    table.insert(TestCardPadding.cards, {card = card2, label = "Tight Padding (10,5,5,5)"})
    
    -- Card 3: Generous padding
    local card3 = UICard(nil, jokerData3, TestCardPadding.font, function() log.info("Card 3 clicked") end)
    card3.x = 550
    card3.y = 100
    card3:setPadding(30, 20, 20, 15, 25)  -- Generous padding
    table.insert(TestCardPadding.cards, {card = card3, label = "Generous Padding (30,20,20,15)"})
    
    -- Card 4: Asymmetric padding
    local card4 = UICard(nil, jokerData1, TestCardPadding.font, function() log.info("Card 4 clicked") end)
    card4.x = 800
    card4.y = 100
    card4:setPadding(25, 15, 5, 10, 22)  -- Asymmetric
    table.insert(TestCardPadding.cards, {card = card4, label = "Asymmetric (25,15,5,10)"})
    
    log.info("Test initialized with " .. #TestCardPadding.cards .. " cards")
end

function TestCardPadding.update(dt)
    if not TestCardPadding.cards then return end
    
    local mx, my = input.getMousePosition()
    local clicked = input.isPressed("mouse_left")
    
    -- Update all cards
    for _, cardData in ipairs(TestCardPadding.cards) do
        cardData.card:update(dt, mx, my, clicked)
    end
    
    -- Exit on ESC
    if input.isPressed("escape") then
        log.info("Exiting card padding test")
        os.exit(0)
    end
end

function TestCardPadding.draw()
    if not TestCardPadding.cards then return end
    
    local screenW = Window.getWidth()
    local screenH = Window.getHeight()
    
    -- Background
    graphics.drawRect(0, 0, screenW, screenH, {r=0.1, g=0.1, b=0.12, a=1}, true)
    
    -- Title
    graphics.print(TestCardPadding.font, "UICard Padding Test - Press ESC to exit", 20, 20, {r=1, g=1, b=1, a=1})
    graphics.print(TestCardPadding.font, "Hover over cards to see the hover effect", 20, 45, {r=0.7, g=0.7, b=0.7, a=1})
    
    -- Draw all cards with labels
    for _, cardData in ipairs(TestCardPadding.cards) do
        -- Draw card
        cardData.card:draw()
        
        -- Draw label above card
        local labelW = graphics.getTextSize(TestCardPadding.font, cardData.label)
        local labelX = cardData.card.x + (cardData.card.width - labelW) / 2
        graphics.print(TestCardPadding.font, cardData.label, labelX, cardData.card.y - 25, {r=1, g=0.8, b=0.2, a=1})
    end
    
    -- Instructions
    local instrY = 450
    graphics.print(TestCardPadding.font, "Padding format: (top, left, right, bottom, lineSpacing)", 50, instrY, {r=0.8, g=0.8, b=0.8, a=1})
    graphics.print(TestCardPadding.font, "Use setPadding() to customize spacing around description text", 50, instrY + 25, {r=0.8, g=0.8, b=0.8, a=1})
    graphics.print(TestCardPadding.font, "Header, footer, and description text all perfectly centered!", 50, instrY + 50, {r=0.4, g=1, b=0.4, a=1})
    
    -- Show default values
    graphics.print(TestCardPadding.font, "Default values: top=20, left=10, right=10, bottom=10, lineSpacing=20", 50, instrY + 75, {r=0.6, g=0.6, b=0.6, a=1})
end

-- Initialize
TestCardPadding.init()

function love_update(dt)
    TestCardPadding.update(dt)
end

function love_draw()
    TestCardPadding.draw()
end
