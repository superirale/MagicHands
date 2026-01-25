-- UILogic.lua
-- Handles updates and animations (Controller)

UILogic = {}

function UILogic.update(dt)
    -- Lerp Display Health towards Real Health
    local speed = 5.0
    local diff = UIData.health - UIData.displayHealth
    
    if math.abs(diff) > 0.1 then
        UIData.displayHealth = UIData.displayHealth + (diff * speed * dt)
    else
        UIData.displayHealth = UIData.health
    end
end

-- Call this when player takes damage
function UILogic.onDamage(amount)
    UIData.health = math.max(0, UIData.health - amount)
    -- Add screen shake or flash trigger here later
end

return UILogic
