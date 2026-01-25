# UI System Guide

Comprehensive guide to the data-driven, Hades-style UI system.

---

## Overview

The UI system uses **declarative definitions** (like Hades) where elements are defined as Lua tables with properties for position, graphics, text, opacity, and relationships.

### Key Features
- ✅ Declarative element definitions
- ✅ Inheritance via `InheritFrom`
- ✅ Parent-child attachments via `AttachTo`
- ✅ Opacity fade animations
- ✅ Z-Order layering control

---

## Core Components

### UIDefinitions.lua
Defines all UI elements as a table:

```lua
UIDefinitions = {
    HealthBarBackground = {
        Graphic = "ui_bar_bg",
        X = 20,
        Y = 20,
        Width = 200,
        Height = 24,
        ZOrder = 1,
    },
    
    HealthText = {
        X = 230,
        Y = 23,
        Font = "content/fonts/font.ttf",
        FontSize = 18,
        TextRed = 0.95,
        TextGreen = 0.95,
        TextBlue = 0.95,
        Text = "100/100",
        ZOrder = 10,
    }
}
```

### UIElement.lua
Base class for all UI elements. Handles:
- Position calculation (world coords)
- Opacity fade animations
- Resource loading (textures, fonts)
- Rendering (graphics + text)

### UIManager.lua
- Parses `UIDefinitions`
- Creates `UIElement` instances
- Resolves `InheritFrom` and `AttachTo`
- Provides `get()`, `show()`, `hide()` API

---

## Element Properties

| Property | Type | Description |
|----------|------|-------------|
| `X`, `Y` | number | Position (screen space) |
| `OffsetX`, `OffsetY` | number | Offset from parent (if `AttachTo` set) |
| `Width`, `Height` | number | Size in pixels |
| `Graphic` | string | Texture name (without `.png`) |
| `Font` | string | Path to .ttf file |
| `FontSize` | number | Font size in pixels |
| `TextRed/Green/Blue` | number (0-1) | Text color |
| `Text` | string | Text content |
| `FadeOpacity` | number (0-1) | Current opacity |
| `FadeTarget` | number (0-1) | Target opacity (animates) |
| `FadeSpeed` | number | Lerp speed (default: 5) |
| `ZOrder` | number | Draw order (lower = first) |
| `InheritFrom` | string | Parent definition name |
| `AttachTo` | string | Parent element name |

---

## Inheritance Example

Define a base style and inherit from it:

```lua
UIDefinitions = {
    -- Base button style
    BaseButton = {
        Width = 200,
        Height = 50,
        Graphic = "button_bg",
        FontSize = 20,
        TextRed = 1.0,
        TextGreen = 1.0,
        TextBlue = 1.0,
    },
    
    -- Start button inherits base
    StartButton = {
        InheritFrom = "BaseButton",
        X = 640,
        Y = 400,
        Text = "Start Game",
    },
    
    -- Quit button also inherits
    QuitButton = {
        InheritFrom = "BaseButton",
        X = 640,
        Y = 470,
        Text = "Quit",
    },
}
```

---

## Parent-Child Attachments

Elements can attach to parents with `AttachTo`:

```lua
UIDefinitions = {
    -- Parent element
    DialogBox = {
        X = 400,
        Y = 300,
        Width = 500,
        Height = 200,
        Graphic = "dialog_bg",
    },
    
    -- Child text attached to dialog
    DialogText = {
        AttachTo = "DialogBox",
        OffsetX = 20,
        OffsetY = 20,
        Font = "content/fonts/font.ttf",
        FontSize = 18,
        Text = "Welcome to the dungeon!",
    },
}
```

**World Position Calculation**:
```
child.worldX = parent.worldX + child.OffsetX
child.worldY = parent.worldY + child.OffsetY
```

---

## Fade Animations

Elements automatically lerp from `FadeOpacity` to `FadeTarget`:

```lua
-- Start hidden
SubtitlesBacking = {
    X = 640, Y = 600,
    FadeOpacity = 0.0,
    FadeTarget = 0.0,
}
```

Show via code:
```lua
UIManager.show("SubtitlesBacking") -- Fades to 1.0
```

Hide:
```lua
UIManager.hide("SubtitlesBacking", true) -- Immediate (skip animation)
```

---

## Z-Order Layering

Control draw order with `ZOrder` (lower draws first):

```lua
-- Background (drawn first)
HealthBarBackground = {
    ZOrder = 1,
}

-- Fill (drawn second, on top of background)
HealthBarFill = {
    ZOrder = 5,
}

-- Border (drawn last, frames everything)
HealthBarBorder = {
    ZOrder = 10,
}
```

---

## Dynamic Updates

Update element properties at runtime:

```lua
function UI.update(dt)
    -- Update health bar width
    local healthEl = UIManager.get("HealthBarFill")
    if healthEl then
        local pct = UIData.health / UIData.maxHealth
        healthEl.Width = 196 * pct
    end
    
    -- Update text
    local textEl = UIManager.get("HealthText")
    if textEl then
        textEl.text = UIData.health .. "/" .. UIData.maxHealth
    end
    
    UIManager.update(dt) -- Process fade animations
end
```

---

## Best Practices

### 1. Use Inheritance for Common Styles
Define base styles for buttons, panels, etc.

### 2. Group Related Elements
```lua
-- Group with prefixes
HUD_HealthBar = { ... },
HUD_HealthText = { ... },
HUD_AmmoIcon1 = { ... },
```

### 3. Explicit Z-Order
Always set `ZOrder` for layered elements to avoid rendering issues.

### 4. Responsive Positioning
For centered elements:
```lua
X = 640,  -- Screen width / 2
Justification = "Center",
```

### 5. Fade for Polish
Use `FadeTarget` instead of instant show/hide for smoother UX.

---

## Example: Health Bar

```lua
UIDefinitions = {
    HealthBarBorder = {
        Graphic = "ui_bar_border",
        X = 20, Y = 20,
        Width = 200, Height = 24,
        ZOrder = 10,
    },
    
    HealthBarBackground = {
        Graphic = "ui_bar_bg",
        X = 22, Y = 22,
        Width = 196, Height = 20,
        ZOrder = 1,
    },
    
    HealthBarFill = {
        Graphic = "ui_bar_fill",
        X = 22, Y = 22,
        Width = 196,  -- Dynamic, updated in UI.lua
        Height = 20,
        ZOrder = 5,
    },
    
    HealthText = {
        X = 230, Y = 23,
        Font = "content/fonts/font.ttf",
        FontSize = 18,
        TextRed = 0.95,
        Text = "100/100",
        ZOrder = 20,
    },
}
```

**Result**: Border frames the bar, background is dark, fill (red) animates with health, text displays current value.
