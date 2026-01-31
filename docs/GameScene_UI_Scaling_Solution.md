# GameScene UI Scaling Solution

## The Real Issue

GameScene uses a **fixed 1280x720 viewport** that gets scaled by the engine:

```lua
self.camera = Camera({ viewportWidth = 1280, viewportHeight = 720 })
graphics.setViewport(1280, 720)
```

This means:
- Game world is always 1280x720
- Engine scales/letterboxes this to fit any window size
- UI is drawn in 1280x720 space, then scaled by engine

## Current Behavior

**What should happen:**
- Window at 1280x720: UI looks normal
- Window at 1920x1080: Engine scales 1280x720 viewport to fit, UI scales too
- Everything should "just work" because UI is in viewport space

**What might be wrong:**
- UI elements using window size instead of viewport size
- UI elements not respecting viewport boundaries
- Some UI drawn in window space, some in viewport space

## Solution: Consistent Viewport Usage

All UI should use viewport size (1280x720) not window size:

```lua
-- WRONG - uses window size
local winW, winH = graphics.getWindowSize()  -- Could be 1920x1080
local buttonX = winW / 2  -- Wrong! Button at 960, outside viewport

-- CORRECT - uses viewport size  
local viewW, viewH = 1280, 720  -- Fixed viewport
local buttonX = viewW / 2  -- Correct! Button at 640, in viewport
```

## Check These UI Components

### 1. HUD (UI/HUD.lua)
- Does it use window size or viewport size?
- Positions should be in 1280x720 space

### 2. ShopUI (UI/ShopUI.lua)
- Cards positioning
- Button positions
- Should all be in 1280x720 space

### 3. BlindPreview (UI/BlindPreview.lua)
- Modal centering
- Should center in 1280x720, not window size

### 4. DeckView (UI/DeckView.lua)
- Card grid layout
- Should fit in 1280x720 space

### 5. CollectionUI (UI/CollectionUI.lua)
- Tab positions
- Scroll area
- Should use 1280x720 space

## Quick Test

Add this to GameScene:draw() at the very end:

```lua
-- Draw viewport boundary (red rectangle)
local viewW, viewH = 1280, 720
graphics.drawRect(0, 0, viewW, viewH, {r=1, g=0, b=0, a=1}, false)
graphics.drawRect(5, 5, viewW-10, viewH-10, {r=1, g=0, b=0, a=1}, false)
```

This shows the 1280x720 viewport. If UI elements are outside this box, they're using window size incorrectly!

## Recommended Fix

**For MenuScene:**
- Keep the scaling system we implemented
- MenuScene doesn't use a fixed viewport, so it needs manual scaling

**For GameScene:**
- Remove the scaling system I just added
- Make sure all UI uses 1280x720 coordinates
- Let the engine handle scaling via viewport

**The rule:**
- MenuScene: Manual UI scaling (no fixed viewport)
- GameScene: Fixed 1280x720 viewport, no manual scaling needed

## Next Steps

1. Verify which UI components use `graphics.getWindowSize()`
2. Change them to use viewport size (1280, 720)
3. Test at different resolutions
4. UI should scale automatically with viewport

---

Would you like me to audit all GameScene UI components and fix their sizing?
