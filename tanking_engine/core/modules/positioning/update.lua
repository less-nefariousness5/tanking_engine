---@type color
local color = require("common/color")

---Update player position history
local function update_player_position_history()
    local module = TankEngine.modules.positioning
    local me = TankEngine.variables.me
    local position = me:get_position()
    
    -- Add current position to history
    table.insert(module.player_position_history, {
        x = position.x,
        y = position.y,
        z = position.z,
        time = core.game_time()
    })
    
    -- Trim history to maintain maximum length
    while #module.player_position_history > module.settings.position_history_length do
        table.remove(module.player_position_history, 1)
    end
end

---Check if player should start kiting
---@return boolean
local function should_start_kiting()
    local module = TankEngine.modules.positioning
    local me = TankEngine.variables.me
    
    -- Get current health percentage
    local health_pct = me:get_health() / me:get_max_health()
    
    -- Check if health below kiting threshold
    if health_pct <= module.settings.kiting_threshold() then
        -- Verify that we have major cooldowns on cooldown
        local have_cooldowns_available = TankEngine.modules.mitigation.get_best_major_defensive() ~= nil
        
        -- Only kite if we don't have major cooldowns available
        return not have_cooldowns_available
    end
    
    return false
end

---Check if player should stop kiting
---@return boolean
local function should_stop_kiting()
    local module = TankEngine.modules.positioning
    local me = TankEngine.variables.me
    
    -- Get current health percentage
    local health_pct = me:get_health() / me:get_max_health()
    
    -- Stop kiting if health recovered or cooldowns available
    if health_pct > module.settings.kiting_threshold() + 0.1 or
       TankEngine.modules.mitigation.get_best_major_defensive() ~= nil then
        return true
    end
    
    return false
end

---Perform fast updates for positioning
function TankEngine.modules.positioning.on_fast_update()
    local current_time = core.game_time()
    
    -- Only update at specified intervals
    if current_time - TankEngine.modules.positioning.last_update < TankEngine.modules.positioning.update_interval then
        return
    end
    
    -- Update player position history
    update_player_position_history()
    
    -- Check if we should change kiting state
    if TankEngine.modules.positioning.is_kiting then
        if should_stop_kiting() then
            TankEngine.modules.positioning.is_kiting = false
            TankEngine.modules.positioning.kiting_path = {}
        end
    else
        if should_start_kiting() then
            TankEngine.modules.positioning.is_kiting = true
            TankEngine.modules.positioning.generate_kiting_path()
        end
    end
    
    -- Update recommended position
    if TankEngine.modules.positioning.is_kiting then
        TankEngine.modules.positioning.update_kiting_position()
    else
        TankEngine.modules.positioning.recommended_position = 
            TankEngine.modules.positioning.find_optimal_position()
    end
    
    -- Record last update
    TankEngine.modules.positioning.last_update = current_time
end

---Process main update logic for positioning
function TankEngine.modules.positioning.on_update()
    local module = TankEngine.modules.positioning
    
    -- Only proceed if auto-positioning is enabled
    if not module.settings.auto_position() then
        return
    end
    
    -- If we have a recommended position, try to move there
    if module.recommended_position then
        local me = TankEngine.variables.me
        local current_pos = me:get_position()
        
        -- Calculate distance to recommended position
        local dx = module.recommended_position.x - current_pos.x
        local dy = module.recommended_position.y - current_pos.y
        local distance = math.sqrt(dx*dx + dy*dy)
        
        -- Only move if significantly distant from current position
        if distance > 2.0 then
            -- TODO: Implement actual movement
            -- For now, just log the recommendation
            core.log(string.format("Recommend moving to position (%.1f, %.1f)", 
                module.recommended_position.x, module.recommended_position.y))
        end
    end
end

---Custom render function for positioning visualization
function TankEngine.modules.positioning.on_render()
    local module = TankEngine.modules.positioning
    local tag = "tank_engine_"
    
    -- Get checkbox states using the proper settings functions
    local show_positioning = module.settings.show_positioning()
    local show_kiting_path = module.settings.show_kiting_path()
    local position_color = TankEngine.modules.positioning.menu.position_color:get()
    
    -- Visualize recommended position if enabled
    if show_positioning and module.recommended_position then
        -- Draw a circle at the recommended position
        core.graphics.circle_3d(
            module.recommended_position,  -- center point (vec3)
            1.0,  -- radius
            position_color,
            2.0   -- thickness
        )
    end
    
    -- Visualize kiting path if enabled
    if show_kiting_path and module.is_kiting and #module.kiting_path > 0 then
        -- Draw lines connecting kiting path points
        for i = 1, #module.kiting_path - 1 do
            local p1 = module.kiting_path[i]
            local p2 = module.kiting_path[i + 1]
            
            core.graphics.line_3d(
                p1,  -- start point (vec3)
                p2,  -- end point (vec3)
                position_color,
                1.5  -- thickness
            )
        end
    end
end
