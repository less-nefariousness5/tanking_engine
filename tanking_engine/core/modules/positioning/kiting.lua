---Generate a kiting path for emergency situations
function TankEngine.modules.positioning.generate_kiting_path()
    local module = TankEngine.modules.positioning
    local me = TankEngine.variables.me
    local my_pos = me:get_position()
    
    -- Clear existing path
    module.kiting_path = {}
    
    -- Start with current position
    table.insert(module.kiting_path, {
        x = my_pos.x,
        y = my_pos.y,
        z = my_pos.z,
        reached = true
    })
    
    -- Find safe retreat position
    local retreat_pos = module.find_safe_retreat_position()
    
    if not retreat_pos then
        -- If no retreat position, create a simple circular kiting path
        local radius = module.settings.kiting_distance
        local center_x, center_y = my_pos.x, my_pos.y
        
        -- Create points in a circle
        for i = 1, 8 do
            local angle = (i - 1) * math.pi / 4
            local x = center_x + radius * math.cos(angle)
            local y = center_y + radius * math.sin(angle)
            
            table.insert(module.kiting_path, {
                x = x,
                y = y,
                z = my_pos.z,
                reached = false
            })
        end
    else
        -- Use the retreat position as a starting point
        table.insert(module.kiting_path, {
            x = retreat_pos.x,
            y = retreat_pos.y,
            z = retreat_pos.z,
            reached = false
        })
        
        -- Generate additional kiting points in a pattern
        local base_x, base_y = retreat_pos.x, retreat_pos.y
        local distance = module.settings.safe_zone_radius()
        
        -- Add points in a zigzag pattern
        for i = 1, 3 do
            -- Left point
            table.insert(module.kiting_path, {
                x = base_x - distance,
                y = base_y + distance * i,
                z = retreat_pos.z,
                reached = false
            })
            
            -- Right point
            table.insert(module.kiting_path, {
                x = base_x + distance,
                y = base_y + distance * i,
                z = retreat_pos.z,
                reached = false
            })
        end
    end
    
    -- Log kiting path generation
    core.log("Generated kiting path with " .. #module.kiting_path .. " points")
end

---Update current kiting position based on path
function TankEngine.modules.positioning.update_kiting_position()
    local module = TankEngine.modules.positioning
    local me = TankEngine.variables.me
    local my_pos = me:get_position()
    
    -- If no kiting path, generate one
    if #module.kiting_path == 0 then
        module.generate_kiting_path()
    end
    
    -- Find the next unreached point in the path
    local next_point = nil
    for i, point in ipairs(module.kiting_path) do
        if not point.reached then
            next_point = point
            break
        end
    end
    
    -- If all points reached, cycle back to the beginning
    if not next_point then
        for i, point in ipairs(module.kiting_path) do
            point.reached = false
        end
        
        -- Skip the first point (current position)
        if #module.kiting_path > 1 then
            next_point = module.kiting_path[2]
        else
            -- If only one point, regenerate path
            module.generate_kiting_path()
            next_point = module.kiting_path[1]
        end
    end
    
    -- Check if we've reached the current target point
    if next_point then
        local dx = next_point.x - my_pos.x
        local dy = next_point.y - my_pos.y
        local distance = math.sqrt(dx*dx + dy*dy)
        
        if distance < 2.0 then
            next_point.reached = true
            
            -- Move to the next point
            for i, point in ipairs(module.kiting_path) do
                if not point.reached then
                    next_point = point
                    break
                end
            end
        end
        
        -- Set recommended position to the next point
        module.recommended_position = {
            x = next_point.x,
            y = next_point.y,
            z = next_point.z
        }
    else
        -- Fallback to current position if no next point
        module.recommended_position = my_pos
    end
    
    -- Check if kiting is still necessary
    if module.should_stop_kiting and module.should_stop_kiting() then
        module.is_kiting = false
        module.kiting_path = {}
    end
end

---Adjust kiting path to avoid obstacles or enemies
---@param obstacles table[] Array of obstacles to avoid
function TankEngine.modules.positioning.adjust_kiting_path(obstacles)
    local module = TankEngine.modules.positioning
    
    -- Skip if no kiting path
    if #module.kiting_path == 0 then
        return
    end
    
    -- For each point in the path, check if it's too close to an obstacle
    for i, point in ipairs(module.kiting_path) do
        if not point.reached then
            local too_close = false
            
            for _, obstacle in ipairs(obstacles) do
                local dx = point.x - obstacle.x
                local dy = point.y - obstacle.y
                local distance = math.sqrt(dx*dx + dy*dy)
                
                -- If too close to obstacle, adjust point
                if distance < obstacle.radius then
                    too_close = true
                    
                    -- Direction away from obstacle
                    local nx, ny = dx / distance, dy / distance
                    
                    -- Move point away from obstacle
                    point.x = obstacle.x + nx * (obstacle.radius + 2)
                    point.y = obstacle.y + ny * (obstacle.radius + 2)
                end
            end
            
            -- Check if point is now too close to any enemies
            for _, enemy in ipairs(TankEngine.variables.nearby_enemies) do
                if enemy and enemy:is_valid() and not enemy:is_dead() then
                    local enemy_pos = enemy:get_position()
                    local dx = point.x - enemy_pos.x
                    local dy = point.y - enemy_pos.y
                    local distance = math.sqrt(dx*dx + dy*dy)
                    
                    -- If too close to enemy, adjust point
                    if distance < 8.0 then
                        too_close = true
                        
                        -- Direction away from enemy
                        local nx, ny = dx / distance, dy / distance
                        
                        -- Move point away from enemy
                        point.x = enemy_pos.x + nx * 10
                        point.y = enemy_pos.y + ny * 10
                    end
                end
            end
        end
    end
end

---Check if a location is safe for kiting
---@param pos table Position with x, y, z fields
---@return boolean is_safe Whether the position is safe
function TankEngine.modules.positioning.is_position_safe(pos)
    -- Check distance to enemies
    for _, enemy in ipairs(TankEngine.variables.nearby_enemies) do
        if enemy and enemy:is_valid() and not enemy:is_dead() then
            local enemy_pos = enemy:get_position()
            local dx = pos.x - enemy_pos.x
            local dy = pos.y - enemy_pos.y
            local distance = math.sqrt(dx*dx + dy*dy)
            
            -- If too close to enemy, not safe
            if distance < 5.0 then
                return false
            end
        end
    end
    
    -- Check for hazards (to be implemented with actual game mechanics)
    -- For example, checking for void zones, fire, etc.
    
    return true
end

---Get the current kiting status
---@return boolean is_kiting Whether currently kiting
---@return table|nil next_position Next position to move to, or nil if not kiting
function TankEngine.modules.positioning.get_kiting_status()
    local module = TankEngine.modules.positioning
    
    if not module.is_kiting or #module.kiting_path == 0 then
        return false, nil
    end
    
    -- Find the next unreached point
    for _, point in ipairs(module.kiting_path) do
        if not point.reached then
            return true, point
        end
    end
    
    return true, nil
end

---Check if we're in a safe zone
---@param pos table Position with x, y, z fields
---@return boolean is_safe Whether the position is in a safe zone
function TankEngine.modules.positioning.is_in_safe_zone(pos)
    local module = TankEngine.modules.positioning
    
    -- Check distance to all safe zones
    for _, safe_zone in ipairs(safe_zones) do
        local distance = module.settings.safe_zone_radius()
        if core.get_distance_between(pos, safe_zone) <= distance then
            return true
        end
    end
    return false
end
