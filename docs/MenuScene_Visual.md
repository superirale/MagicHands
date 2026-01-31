# MenuScene Visual Design

## Layout Preview

```
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║                                                                ║
║                        MAGIC HANDS                             ║
║                                                                ║
║                   A Cribbage Roguelike                         ║
║                                                                ║
║                                                                ║
║                                                                ║
║                  ┌──────────────────────┐                      ║
║                  │   START NEW GAME     │  ← Green button     ║
║                  └──────────────────────┘                      ║
║                                                                ║
║                  ┌──────────────────────┐                      ║
║                  │      CONTINUE        │  ← Blue (disabled)  ║
║                  └──────────────────────┘                      ║
║                                                                ║
║                  ┌──────────────────────┐                      ║
║                  │      SETTINGS        │  ← Gray button      ║
║                  └──────────────────────┘                      ║
║                                                                ║
║                  ┌──────────────────────┐                      ║
║                  │        EXIT          │  ← Red button       ║
║                  └──────────────────────┘                      ║
║                                                                ║
║                                                                ║
║ v0.1.0        Click to select • [↑↓] Navigate • [Enter] Confirm
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
```

## Button States

### START NEW GAME (Always Enabled)
```
┌──────────────────────────────────┐
│       START NEW GAME             │  Normal (green)
└──────────────────────────────────┘

┌──────────────────────────────────┐
│       START NEW GAME             │  Hovered (lighter green)
└──────────────────────────────────┘

┌══════════════════════════════════┐
║╔════════════════════════════════╗║
║║     START NEW GAME             ║║  Selected (controller - orange border)
║╚════════════════════════════════╝║
└──────────────────────────────────┘
```

### CONTINUE (Disabled when no save)
```
┌──────────────────────────────────┐
│         CONTINUE                 │  Disabled (grayed out)
└──────────────────────────────────┘

┌──────────────────────────────────┐
│         CONTINUE                 │  Enabled (blue)
└──────────────────────────────────┘

┌──────────────────────────────────┐
│         CONTINUE                 │  Hovered (lighter blue)
└──────────────────────────────────┘
```

## Color Scheme

### Background
- Dark gray/blue: `Theme.get("colors.panelBgActive")`
- RGB: ~(26, 26, 33) - Darkest panel color

### Title
- Bright blue: `Theme.get("colors.primary")`
- RGB: ~(59, 130, 246)
- Font: Roboto Bold 72pt

### Subtitle
- Muted gray: `Theme.get("colors.textMuted")`
- RGB: ~(156, 163, 175)
- Font: Roboto Regular 32pt

### Button Colors

| Button | Style | Default | Hover | Active | Disabled |
|--------|-------|---------|-------|--------|----------|
| Start | success | Green #10B981 | Lighter | Darker | Gray |
| Continue | primary | Blue #3B82F6 | Lighter | Darker | #6B7280 |
| Settings | secondary | Gray #6B7280 | Lighter | Darker | Dark Gray |
| Exit | danger | Red #EF4444 | Lighter | Darker | Gray |

### Selection Indicator (Gamepad)
- Color: Orange/Gold `Theme.get("colors.warning")`
- Style: 3-pixel border around button
- Only visible when gamepad is active

## Dimensions

### Screen
- Designed for: 1280x720 minimum
- Responsive: Yes (buttons re-center on resize)

### Title
- Font size: 72pt (bold)
- Position: Top center, Y=100

### Subtitle
- Font size: 32pt (regular)
- Position: Below title, Y=190

### Buttons
- Width: 300px
- Height: 70px
- Spacing: 20px between buttons
- Font size: 32pt (bold)
- Position: Centered horizontally, starting Y=310

### Version Text
- Font size: 18pt
- Position: Bottom-left (10, H-30)

### Hint Text
- Font size: 18pt
- Position: Bottom-center

## Animations (Future)

### Button Hover
- Smooth color transition (0.2s)
- Slight scale increase (1.05x)
- Glow effect

### Scene Transition
- Fade out (0.3s)
- Fade in GameScene (0.3s)

### Title
- Gentle float animation (±5px)
- Fade in on scene enter (0.5s)

### Buttons
- Cascade fade-in (0.1s delay each)
- Slide in from left/right

## Responsive Behavior

### Window Resize
1. Layout recalculates button positions
2. Title stays centered
3. Buttons stay centered
4. Version/hint text adjust to new dimensions

### Small Screen (<1280x720)
- Buttons stack closer (reduced spacing)
- Title font size scales down
- Hint text may wrap

### Large Screen (>1920x1080)
- Elements stay centered
- Max button width maintained
- Empty space on sides

## Accessibility

### Keyboard Navigation
- Tab key: Next button (future)
- Shift+Tab: Previous button (future)
- Arrow keys: Navigate
- Enter/Space: Activate
- Escape: Exit menu (future)

### Gamepad Navigation
- D-pad/Left stick: Navigate
- A button: Confirm
- B button: Cancel/Back (future)
- Visual indicator shows selection

### Screen Reader Support (Future)
- Button labels announced
- State changes announced
- Disabled state indicated

### High Contrast Mode (Future)
- Alternative color scheme
- Higher contrast ratios
- Thicker borders

### Colorblind Support
- Already uses Theme system
- Can switch to "deuteranopia" theme
- Shapes/icons in addition to colors (future)

## Comparison with TitleScene

| Feature | TitleScene (Old) | MenuScene (New) |
|---------|------------------|-----------------|
| UI Framework | Raw input/graphics | Phase 1 UI Components |
| Buttons | Text-based menu | UIButton components |
| Theme | Hardcoded colors | Theme system |
| Input | Keyboard only | Mouse + Keyboard + Gamepad |
| Controller | No | Full support |
| Responsive | No | Yes |
| Style | Classic menu | Modern UI |
| Continue | No | Yes (with save check) |
| Settings | No | Yes (placeholder) |

## Theme Variants

### Default Theme
- Dark background
- Blue primary color
- Clean and modern

### Colorblind Theme (Deuteranopia)
- Adjusted colors for red-green colorblindness
- Blue/Yellow palette
- Same layout

### High Contrast Theme (Future)
- Black/White with accent
- Thicker borders
- Larger text

## Implementation Notes

### Button Creation
```lua
self.startButton = UIButton(nil, "START NEW GAME", self.font, function()
    self:startNewGame()
end, "success")
```

### Layout Management
```lua
self.layout = UILayout(winW, winH)
```

### Theme Usage
```lua
self.colors = {
    background = Theme.get("colors.panelBgActive"),  -- Darkest panel color
    title = Theme.get("colors.primary"),
    subtitle = Theme.get("colors.textMuted"),
    version = Theme.get("colors.textDisabled")
}
```

### Controller Selection
```lua
-- Draw selection indicator for controller
if i == self.selectedIndex and inputmgr.isGamepad() then
    local borderColor = Theme.get("colors.warning")
    for j = 0, 2 do
        graphics.drawRect(button.x - j - 2, button.y - j - 2, 
                        button.width + (j + 2) * 2, button.height + (j + 2) * 2, 
                        borderColor, false)
    end
end
```

---

**Created:** January 31, 2026  
**Last Updated:** January 31, 2026
