-- TitleScene.lua
-- Title/menu scene for Magic Hands

TitleScene = class()

function TitleScene:enter()
    print("Entered Title Scene")

    -- Load UI resources
    self.font = assets.loadFont("content/fonts/font.ttf", 24)
    self.bgTexture = graphics.loadTexture("content/images/title_bg.png")
    self.logoTexture = graphics.loadTexture("content/images/logo.png")

    -- Menu State
    self.menuItems = {
        { name = "PLAY", action = function() SceneManager.switch("GameScene", { type = "fade", duration = 1.0 }) end },
        {
            name = "TILEMAP TEST",
            action = function()
                SceneManager.switch("TilemapTestScene",
                    { type = "fade", duration = 0.5 })
            end
        },
        {
            name = "SPATIAL DEMO",
            action = function()
                SceneManager.switch("SpatialDemoScene",
                    { type = "fade", duration = 0.5 })
            end
        },
        { name = "EXIT", action = function() log.warn("Quit not implemented") end }
    }
    self.selectedItem = 1

    -- Play title music
    -- Might remove
    -- audio.playEvent("music_title")
end

function TitleScene:update(dt)
    -- Menu Navigation
    if input.isPressed("up") or input.isPressed("w") then
        self.selectedItem = self.selectedItem - 1
        if self.selectedItem < 1 then self.selectedItem = #self.menuItems end
        audio.playEvent("ui_hover_sound") -- Optional: play sound
    end

    if input.isPressed("down") or input.isPressed("s") then
        self.selectedItem = self.selectedItem + 1
        if self.selectedItem > #self.menuItems then self.selectedItem = 1 end
        audio.playEvent("ui_hover_sound")
    end

    if input.isPressed("return") or input.isPressed("space") then
        local item = self.menuItems[self.selectedItem]
        if item and item.action then
            audio.playEvent("ui_select_sound")
            item.action()
        end
    end
end

function TitleScene:draw()
    local screenWidth = Window.getWidth()
    local screenHeight = Window.getHeight()

    -- 1. Draw Background (Cover)
    if self.bgTexture and self.bgTexture ~= -1 then
        graphics.draw(self.bgTexture, 0, 0, screenWidth, screenHeight, 0, { r = 1, g = 1, b = 1, a = 1 }, true)
    else
        -- Fallback
        graphics.drawRect(0, 0, screenWidth, screenHeight, { r = 0, g = 0.5, b = 0.8, a = 1 }, true)
    end

    -- 2. Draw Logo
    if self.logoTexture and self.logoTexture ~= -1 then
        local logoW = 600 -- approximate or desired width
        local logoH = 200 -- desired height
        -- If we can get texture size, better. Assuming fixed aspect for now or just drawing centered.
        -- C++ Engine API might not expose getWidth yet, so hardcoding display size:
        local x = (screenWidth - logoW) / 2
        local y = 50
        graphics.draw(self.logoTexture, x, y, logoW, logoH, 0, { r = 1, g = 1, b = 1, a = 1 }, true)
    else
        if self.font ~= -1 then
            graphics.print(self.font, "HELHEIM", (screenWidth / 2) - 50, 100)
        end
    end

    -- 3. Draw Menu
    if self.font ~= -1 then
        local startY = screenHeight * 0.6
        local spacing = 40

        for i, item in ipairs(self.menuItems) do
            local text = item.name
            local color = { r = 0.9, g = 0.9, b = 0.9, a = 1.0 }
            local scale = 1.0

            if i == self.selectedItem then
                -- Highlight
                text = "> " .. text .. " <"
                color = { r = 1.0, g = 0.8, b = 0.0, a = 1.0 } -- Gold
                scale = 1.2                                    -- Fake scale if font supports it or just color
            end

            -- Simple centering estimation (char width ~12px for size 24)
            local textWidth = #text * 12
            local x = (screenWidth - textWidth) / 2
            local y = startY + (i - 1) * spacing

            -- Shadow
            graphics.print(self.font, text, x + 2, y + 2, { r = 0, g = 0, b = 0, a = 0.5 })

            -- Text
            graphics.print(self.font, text, x, y, color)
        end
    end
end

return TitleScene
