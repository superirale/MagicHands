-- CRTShader.lua
-- Manages CRT post-processing shader for CRT atmosphere

CRTShader = {}

function CRTShader.init()
    -- Load shader with name "crt"
    local success = graphics.loadShader("crt", "content/shaders/crt.metal")
    if not success then
        print("ERROR: Failed to load CRT shader!")
        return false
    else
        print("Darkness shader loaded successfully")
        return true
    end
end

function CRTShader.setEnabled(enabled)
    graphics.setShaderUniform("name", { enabled })
end

return CRTShader
