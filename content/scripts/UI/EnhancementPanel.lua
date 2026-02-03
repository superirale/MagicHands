-- EnhancementPanel.lua
-- Displays active Augments and Warps on the left side of the screen

local Theme = require("UI.Theme")
local EnhancementManager = require("criblage/EnhancementManager")

local EnhancementPanel = class()

function EnhancementPanel:init(font, smallFont, layout)
    self.font = font
    self.smallFont = smallFont
    self.layout = layout

    -- Register Region
    self.layout:register("HUD_Enhancements", {
        anchor = "mid-left",
        width = 150,
        height = 400,
        offsetX = 20,
        offsetY = -150 -- Adjust to center vertically
    })

    self.colors = {
        text = Theme.get("colors.text"),
        mute = Theme.get("colors.textMuted"),
        augment = { r = 0.4, g = 0.6, b = 1.0, a = 1.0 }, -- Sky blue
        warp = { r = 1.0, g = 0.4, b = 0.8, a = 1.0 }     -- Pink/Purple
    }
end

function EnhancementPanel:draw()
    local x, y = self.layout:getPosition("HUD_Enhancements")

    -- Draw Category Headers
    graphics.print(self.font, "ENGINE", x, y, self.colors.mute)
    y = y + 40

    -- 1. Augments (Hand upgrades)
    if #EnhancementManager.augments > 0 then
        graphics.print(self.smallFont, "Augments", x, y, self.colors.augment)
        y = y + 20
        for i, aug in ipairs(EnhancementManager.augments) do
            local str = aug.id:gsub("planet_", "")
            if aug.count > 1 then
                str = str .. " Lvl " .. aug.count
            end
            graphics.print(self.smallFont, "- " .. str, x + 10, y, self.colors.text)
            y = y + 20
        end
        y = y + 10
    end

    -- 2. Warps (Rule benders)
    if #EnhancementManager.warps > 0 then
        graphics.print(self.smallFont, "Warps (" .. #EnhancementManager.warps .. "/3)", x, y, self.colors.warp)
        y = y + 20
        for i, warp in ipairs(EnhancementManager.warps) do
            local str = warp.id:gsub("warp_", ""):gsub("spectral_", "")

            -- Warp animation placeholder (subtle pulse)
            local pulse = 0.8 + math.sin(os.clock() * 2) * 0.2
            local warpColor = {
                r = self.colors.warp.r,
                g = self.colors.warp.g,
                b = self.colors.warp.b,
                a = pulse
            }

            graphics.print(self.smallFont, "⚡ " .. str, x + 10, y, warpColor)
            y = y + 20
        end
    end

    if #EnhancementManager.augments == 0 and #EnhancementManager.warps == 0 then
        graphics.print(self.smallFont, "(No active enhancements)", x + 10, y, self.colors.mute)
    end
end

return EnhancementPanel
