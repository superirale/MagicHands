# Tutorials

Step-by-step guides for common tasks.

---

## Tutorial 1: Adding a New Player Sprite

**Goal**: Replace the default player sprite with your own image.

### Step 1: Prepare Your Image
- Create a 64x64 PNG sprite
- Save as `content/images/my_player.png`

### Step 2: Update Player Code
Edit `content/scripts/main.lua`:

```lua
function Player:init(x, y)
    self.bodyId = physics.createBody(x, y, true)
    
    local tex = graphics.loadTexture("content/images/my_player.png")
    local w, h = graphics.getTextureSize(tex)
    self.anim = Animation(tex, w, h, 0.2, 1)
end
```

### Step 3: Test
Run `./build/MagicHand` and press Space to enter game scene.

---

## Tutorial 2: Creating a Simple Animation

**Goal**: Animate a sprite with 4 frames.

### Step 1: Create Sprite Sheet
- 4 frames horizontally: 256x64 PNG
- Each frame is 64x64
- Save as `content/images/player_walk.png`

### Step 2: Use Animation Component
```lua
function Player:init(x, y)
    self.bodyId = physics.createBody(x, y, true)
    
    local tex = graphics.loadTexture("content/images/player_walk.png")
    self.anim = Animation(tex, 64, 64, 0.15, 4)
    -- 64x64 frames, 0.15s per frame, 4 total frames
end
```

### Step 3: Update and Draw
The `Animation` component auto-updates:
```lua
function Player:update(dt)
    self.anim:update(dt)  -- Advances frames
end

function Player:draw()
    local x, y = physics.getPosition(self.bodyId)
    self.anim:draw(x - 32, y - 32, 64, 64)
end
```

---

## Tutorial 3: Adding a Custom UI Element

**Goal**: Display a coin counter in the top-right.

### Step 1: Define UI Element
Edit `content/scripts/UIDefinitions.lua`:

```lua
UIDefinitions = {
    -- ... existing elements ...
    
    CoinIcon = {
        Graphic = "coin_icon",
        X = 1180,
        Y = 20,
        Width = 32,
        Height = 32,
        ZOrder = 1,
    },
    
    CoinText = {
        X = 1220,
        Y = 23,
        Font = "content/fonts/font.ttf",
        FontSize = 20,
        TextRed = 1.0,
        TextGreen = 0.9,
        TextBlue = 0.3,
        Text = "0",
        ZOrder = 10,
    },
}
```

### Step 2: Add Coin Data
Edit `content/scripts/UIData.lua`:

```lua
UIData = {
    health = 100,
    maxHealth = 100,
    coins = 0,  -- NEW
}
```

### Step 3: Update Coin Display
Edit `content/scripts/UI.lua`:

```lua
function UI.update(dt)
    -- ... existing health updates ...
    
    -- Update coin text
    local coinText = UIManager.get("CoinText")
    if coinText then
        coinText.text = tostring(UIData.coins)
    end
    
    UIManager.update(dt)
end
```

### Step 4: Test
```lua
-- Anywhere in game code:
UIData.coins = UIData.coins + 10
```

---

## Tutorial 4: Playing a Sound Effect

**Goal**: Play a jump sound when Space is pressed.

### Step 1: Add Sound File
- Place `jump.wav` in `content/audio/`

### Step 2: Play on Jump
Edit `content/scripts/main.lua`:

```lua
function Player:update(dt)
    -- Movement code...
    
    if input.isDown("space") then
        physics.applyForce(self.bodyId, 0, -2000000 * dt)
        audio.playSound("content/audio/jump.wav")
    end
end
```

---

## Tutorial 5: Creating a New Scene

**Goal**: Add a "GameOver" scene.

### Step 1: Define Scene Class
Edit `content/scripts/Scenes.lua`:

```lua
GameOverScene = class()

function GameOverScene:enter()
    print("Game Over!")
    self.font = graphics.loadFont("content/fonts/font.ttf", 36)
end

function GameOverScene:update(dt)
    if input.isDown("space") then
        SceneManager.switch("TitleScene")
    end
end

function GameOverScene:draw()
    graphics.print(self.font, "GAME OVER", 500, 300)
    graphics.print(self.font, "Press Space to Restart", 400, 400)
end
```

### Step 2: Register Scene
Edit `content/scripts/Scenes.lua`:

```lua
SceneManager.scenes = {
    TitleScene = TitleScene(),
    GameScene = GameScene(),
    GameOverScene = GameOverScene(),  -- NEW
}
```

### Step 3: Transition to GameOver
```lua
-- When player dies:
if UIData.health <= 0 then
    SceneManager.switch("GameOverScene")
end
```

---

## Tutorial 6: Loading Map Data from JSON

**Goal**: Define level enemies in JSON.

### Step 1: Create JSON File
`content/level1.json`:

```json
{
    "title": "Forest Level",
    "enemies": [
        {"type": "goblin", "x": 500, "y": 300},
        {"type": "goblin", "x": 700, "y": 300},
        {"type": "orc", "x": 900, "y": 250}
    ]
}
```

### Step 2: Load in Game
```lua
function GameScene:enter()
    local levelData = loadJSON("content/level1.json")
    
    self.enemies = {}
    for _, enemyDef in ipairs(levelData.enemies) do
        local enemy = Enemy(enemyDef.type, enemyDef.x, enemyDef.y)
        table.insert(self.enemies, enemy)
    end
end
```

---

## Tutorial 7: Using Coroutines for Cutscenes

**Goal**: Show timed subtitles.

```lua
function TitleScene:enter()
    thread(function()
        UIManager.show("SubtitlesText")
        
        -- Show first line
        local sub = UIManager.get("SubtitlesText")
        sub.text = "Welcome to Magic Hands..."
        wait(3.0)
        
        -- Show second line
        sub.text = "Prepare for battle!"
        wait(3.0)
        
        -- Hide
        UIManager.hide("SubtitlesText")
    end)
end
```

---

## Tutorial 8: Camera Follow Player

**Goal**: Keep player centered on screen.

```lua
function Player:update(dt)
    -- Movement code...
    
    local px, py = physics.getPosition(self.bodyId)
    
    -- Center camera on player
    graphics.setCamera(px - 640, py - 360)
    -- 640 = screen width / 2, 360 = screen height / 2
end
```

---

## Next Steps

- Explore the [API Reference](./API_REFERENCE.md) for all available functions
- Study the [Architecture](./ARCHITECTURE.md) to understand system internals
- Read the [UI System](./UI_SYSTEM.md) guide for advanced UI features

**Community**: Share your games and mods on the Magic Hands forum!
