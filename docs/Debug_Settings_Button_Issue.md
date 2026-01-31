# Debugging: Buttons Not Working After Settings

## Current Status
Issue persists after initial fix. Adding comprehensive debugging to identify root cause.

## Debug Output Added

### When Opening Settings
```
Opening settings menu...
  Resetting button 1: wasClicked=false, isHovered=false
  Resetting button 2: wasClicked=false, isHovered=false
  Resetting button 3: wasClicked=false, isHovered=false
  Resetting button 4: wasClicked=false, isHovered=false
```

### When Closing Settings
```
Settings closing - resetting menu button states
  Button 1 before reset: wasClicked=false, isHovered=false
  Button 2 before reset: wasClicked=false, isHovered=false
  Button 3 before reset: wasClicked=false, isHovered=false
  Button 4 before reset: wasClicked=false, isHovered=false
```

### When Clicking Buttons
```
START NEW GAME button clicked!
SETTINGS button clicked!
```

## Testing Steps

### Reproduce the Bug
1. Run the game
2. Watch console output
3. Click "SETTINGS" button
   - Should print: "SETTINGS button clicked!"
   - Should print: "Opening settings menu..."
   - Should print button reset info
4. Click "Close" in settings
   - Should print: "Settings closing - resetting menu button states"
   - Should print button states before reset
5. Try clicking "START NEW GAME"
   - **If broken:** No output
   - **If working:** Should print "START NEW GAME button clicked!"

### What to Look For

**Scenario 1: No button callback**
- Button click doesn't print "button clicked!"
- Means `onClick` is not being called
- Issue is in UIButton.update() logic

**Scenario 2: Button states stuck**
- Console shows `wasClicked=true` when closing settings
- Means buttons weren't resetting properly
- Issue is state management

**Scenario 3: Input not reaching buttons**
- No console output at all
- Means buttons.update() not being called
- Issue is in MenuScene.update() flow

## Potential Root Causes

### Theory 1: wasClicked Stuck True
**Symptom:** Button's `wasClicked` never resets to false

**Check:**
```lua
-- In UIButton:update()
print(string.format("Button '%s': isHovered=%s, pressed=%s, wasClicked=%s", 
    self.text, tostring(self.isHoveredState), tostring(pressed), tostring(self.wasClicked)))
```

**Fix:** Already added - reset on open/close

### Theory 2: Input Still Consumed
**Symptom:** `clicked` is true when it should be false

**Check:** Debug output shows clicked=true after settings close

**Fix:** Added `clicked = false` when closing settings

### Theory 3: Update Not Called
**Symptom:** Buttons never get updated after settings close

**Check:** Add print in button update loop:
```lua
for i, button in ipairs(self.buttons) do
    print("Updating button " .. i)
    button:update(dt, mx, my, clicked)
end
```

### Theory 4: Hover Detection Broken
**Symptom:** `isHovered()` returns false even when mouse is over button

**Check:** Add to UIButton:
```lua
function UIButton:isHovered(mx, my)
    local result = mx >= self.x and mx <= self.x + self.width and 
                   my >= self.y and my <= self.y + self.height
    print(string.format("Button '%s' hover check: mx=%d, my=%d, x=%d, y=%d, result=%s",
        self.text, mx, my, self.x, self.y, tostring(result)))
    return result
end
```

### Theory 5: Font Issue Preventing Rendering
**Symptom:** Buttons visible but text not, might affect clickability

**Check:** Already fixed with font validation

**Verify:** Can you see button text?

### Theory 6: Z-Order / Draw Order Issue  
**Symptom:** Settings overlay stays rendered on top

**Check:** Add after settings draw:
```lua
if self.showSettings then
    print("ERROR: showSettings is still true!")
end
```

## Additional Debug Code

### Add to MenuScene:update() after button updates
```lua
-- Update all buttons
for i, button in ipairs(self.buttons) do
    print(string.format("Frame: Updating button %d ('%s'), clicked=%s", 
        i, button.text, tostring(clicked)))
    button:update(dt, mx, my, clicked)
end
```

### Add to UIButton:update() at the start
```lua
function UIButton:update(dt, mx, my, isPressed)
    if not self.visible or self.disabled then 
        print(string.format("Button '%s' skipped: visible=%s, disabled=%s",
            self.text, tostring(self.visible), tostring(self.disabled)))
        return 
    end
    
    print(string.format("Button '%s' updating: mx=%d, my=%d, pressed=%s",
        self.text, mx or -1, my or -1, tostring(isPressed)))
```

## Systematic Testing

### Test 1: Basic Click
1. Start game
2. Click "START NEW GAME" (don't open settings)
3. Expected: "START NEW GAME button clicked!"
4. Result: _______________

### Test 2: After Opening Settings
1. Start game  
2. Click "SETTINGS"
3. Don't close settings, just watch console
4. Expected: Button states reset
5. Result: _______________

### Test 3: After Closing Settings
1. Start game
2. Click "SETTINGS"
3. Click "Close"
4. Watch console output
5. Result: _______________

### Test 4: Click After Closing
1. Start game
2. Click "SETTINGS"
3. Click "Close"
4. Click "START NEW GAME"
5. Expected: "START NEW GAME button clicked!"
6. Result: _______________

### Test 5: Multiple Open/Close
1. Start game
2. Click "SETTINGS" → Close
3. Click "SETTINGS" → Close
4. Click "SETTINGS" → Close
5. Click "START NEW GAME"
6. Expected: Works
7. Result: _______________

## Quick Workaround

If debugging is taking too long, try this nuclear option:

```lua
-- In MenuScene:update(), after closing settings
if result and result.action == "close" then
    self.showSettings = false
    self.settingsUI:close()
    
    -- Nuclear option: Recreate all buttons
    self:recreateButtons()
    
    return  -- Skip this frame entirely
end

-- Add this function
function MenuScene:recreateButtons()
    -- Store callbacks
    local callbacks = {}
    for i, button in ipairs(self.buttons) do
        callbacks[i] = button.onClick
    end
    
    -- Recreate buttons with same callbacks
    self.buttons = {}
    -- ... recreate all buttons with stored callbacks
end
```

## Expected Console Output

### Normal Flow (Working)
```
=== Entered Menu Scene ===
MenuScene fonts loaded:
  titleFont: 0
  font: 1
  smallFont: 2
Menu Scene initialized
SETTINGS button clicked!
Opening settings menu...
  Resetting button 1: wasClicked=false, isHovered=false
  Resetting button 2: wasClicked=false, isHovered=false
  Resetting button 3: wasClicked=false, isHovered=false
  Resetting button 4: wasClicked=false, isHovered=false
Settings closing - resetting menu button states
  Button 1 before reset: wasClicked=false, isHovered=false
  Button 2 before reset: wasClicked=false, isHovered=false
  Button 3 before reset: wasClicked=false, isHovered=false
  Button 4 before reset: wasClicked=false, isHovered=false
START NEW GAME button clicked!
Starting new game...
```

### Broken Flow (Bug)
```
=== Entered Menu Scene ===
MenuScene fonts loaded:
  titleFont: 0
  font: 1
  smallFont: 2
Menu Scene initialized
SETTINGS button clicked!
Opening settings menu...
  Resetting button 1: wasClicked=false, isHovered=false
  Resetting button 2: wasClicked=false, isHovered=false
  Resetting button 3: wasClicked=false, isHovered=false
  Resetting button 4: wasClicked=false, isHovered=false
Settings closing - resetting menu button states
  Button 1 before reset: wasClicked=TRUE, isHovered=true   <-- Problem!
  Button 2 before reset: wasClicked=false, isHovered=false
  Button 3 before reset: wasClicked=false, isHovered=false
  Button 4 before reset: wasClicked=false, isHovered=false
(No output when clicking START - button broken)
```

## Next Steps

1. **Run the game and check console output**
2. **Follow the testing steps above**
3. **Report what you see in the console**
4. **Specifically note:**
   - Do button click messages appear before settings?
   - Do button click messages appear after settings?
   - What do the button state values show?
   - Are all buttons affected or just some?

---

**Please run the game and share the console output!**
This will help identify the exact cause of the issue.
