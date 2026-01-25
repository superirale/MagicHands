--- SplashScene - Loading screen shown during asset loading
--- Displays engine logo/title and loading progress bar (PUBG style)

SplashScene = class()

function SplashScene:enter()
    self.loadingComplete = false
    self.loadProgress = 0
    self.displayProgress = 0
    self.totalAssets = 0
    self.loadedAssets = 0
    self.fadeOutStarted = false
    self.currentAsset = "" -- To show which file is loading

    -- Preload fonts for splash screen UI
    -- Size 24 for main text, Size 16 for footer
    self.font = assets.loadFont("content/fonts/font.ttf", 24)
    self.fontSmall = assets.loadFont("content/fonts/font.ttf", 16)

    -- Load background image directly
    self.bgTexture = graphics.loadTexture("content/images/loading_bg.png")

    -- Start async loading in a coroutine
    self.loadingThread = coroutine.create(function()
        -- Initial delay
        local startTime = os.clock()
        while os.clock() - startTime < 0.1 do
            coroutine.yield()
        end

        local preloadConfig = {
            { path = "content/images", extension = "png",  type = "texture" },
            { path = "content/images", extension = "jpg",  type = "texture" },
            { path = "content/images", extension = "jpeg", type = "texture" },
            { path = "content/fonts",  extension = "ttf",  type = "font" },
            -- Add more directories here as needed, e.g.:
            -- { path = "content/audio", extension = "ogg", type = "audio" }
        }

        local assetsToLoad = {}

        -- Helper to scan directories
        local function scanDirectory(path, extension)
            local files = {}
            -- Construct find command (Mac/Linux compatible)
            local cmd = string.format("find %s -name '*.%s'", path, extension)
            local p = io.popen(cmd)
            if p then
                for file in p:lines() do
                    -- trim whitespace
                    file = file:gsub("^%s*(.-)%s*$", "%1")
                    if #file > 0 then
                        table.insert(files, file)
                    end
                end
                p:close()
            end
            return files
        end

        local function gatherAssets()
            for _, config in ipairs(preloadConfig) do
                local files = scanDirectory(config.path, config.extension)
                for _, file in ipairs(files) do
                    table.insert(assetsToLoad, { path = file, type = config.type })
                end
            end
        end

        -- Try to gather assets
        pcall(gatherAssets)

        -- Additional assets we know about (if any manual ones are needed)


        self.totalAssets = #assetsToLoad + 7 -- +3 for audio/systems

        if #assetsToLoad > 0 then
            -- REALTIME LOADING MODE
            log.info("Starting realtime asset loading for " .. self.totalAssets .. " items")

            -- 1. Load Assets
            for _, asset in ipairs(assetsToLoad) do
                self.currentAsset = asset.path

                if asset.type == "texture" then
                    graphics.loadTexture(asset.path) -- Force load & cache
                elseif asset.type == "audio" then
                    -- audio.loadSound(asset.path) -- Example if we were loading individual sounds
                end

                self.loadedAssets = self.loadedAssets + 1
                self.loadProgress = self.loadedAssets / self.totalAssets
                coroutine.yield() -- Yield after EVERY asset
            end
        else
            -- I need to refactor this all loading must be from the asset manifest and we need a way to track the files being loaded
            -- so that we can show the progress in the splash screen
            -- FALLBACK: Blocking Load
            log.info("Asset discovery failed, falling back to blocking manifest load")
            local loaded, total = assets.loadManifest("content/assets.json")
            self.loadedAssets = loaded
            self.totalAssets = total
            self.loadProgress = 1.0
        end

        -- 5. Audio
        self.currentAsset = "Audio System"
        log.info("Loading audio bank...")
        audio.loadBank("content/audio/events.json")
        self.loadedAssets = self.loadedAssets + 1
        self.loadProgress = 1.0
        coroutine.yield()

        -- Initialize achievement system
        self.currentAsset = "Systems"
        AchievementSystem.init()

        -- Give user time to see 100%
        local doneTime = os.clock()
        while os.clock() - doneTime < 0.5 do
            coroutine.yield()
        end

        self.loadingComplete = true
    end)
end

function SplashScene:update(dt)
    -- Resume loading thread
    if self.loadingThread and coroutine.status(self.loadingThread) ~= "dead" then
        local success, err = coroutine.resume(self.loadingThread)
        if not success then
            log.error("Loading thread error: " .. tostring(err))
        end
    end

    -- Smooth follow for display
    if self.displayProgress < self.loadProgress then
        self.displayProgress = self.displayProgress + dt * 2.0 -- Fast catchup
        if self.displayProgress > self.loadProgress then
            self.displayProgress = self.loadProgress
        end
    end

    if self.loadingComplete and self.displayProgress >= 0.99 and not self.fadeOutStarted then
        self.fadeOutStarted = true
        SceneManager.switch("TitleScene", nil, FadeTransition(0.5))
    end
end

function SplashScene:draw()
    local screenWidth = Window.getWidth()
    local screenHeight = Window.getHeight()

    -- 1. Background Image
    if self.bgTexture and self.bgTexture ~= -1 then
        graphics.draw(self.bgTexture, 0, 0, screenWidth, screenHeight, 0, { r = 1, g = 1, b = 1, a = 1 }, true)
    else
        graphics.drawRect(0, 0, screenWidth, screenHeight, { r = 0.05, g = 0.05, b = 0.07, a = 1.0 }, true)
    end

    -- Layout Dimensions
    local barWidth = screenWidth * 0.9
    local barHeight = 6
    local barX = (screenWidth - barWidth) / 2
    local barY = screenHeight - 120

    -- 2. Bar Background
    graphics.drawRect(barX, barY, barWidth, barHeight, { r = 0.3, g = 0.3, b = 0.3, a = 1.0 }, true)

    -- 3. Bar Fill
    local fillWidth = barWidth * self.displayProgress
    if fillWidth > 0 then
        graphics.drawRect(barX, barY, fillWidth, barHeight, { r = 1.0, g = 0.8, b = 0.0, a = 1.0 }, true)
    end

    -- 4. Text
    if self.font and self.font ~= -1 then
        graphics.print(self.font, "LOADING", barX, barY - 35)

        local percentText = string.format("%d%%", math.floor(self.displayProgress * 100))
        local textWidth = #percentText * 15
        graphics.print(self.font, percentText, barX + barWidth - textWidth, barY - 35)

        -- Debug: Show current asset (optional, maybe distracting but proves realtime)
        -- graphics.print(self.fontSmall, self.currentAsset, barX + 100, barY - 30)
    end

    -- 5. Footer
    if self.fontSmall and self.fontSmall ~= -1 then
        local copyrightText = "COPYRIGHT © ALL RIGHTS RESERVED"
        local textWidth = #copyrightText * 10
        local textX = (screenWidth - textWidth) / 2
        local textY = screenHeight - 40
        graphics.print(self.fontSmall, copyrightText, textX, textY)
    end

    graphics.flush()
end

return SplashScene
