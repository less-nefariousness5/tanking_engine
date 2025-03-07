-- Pathing patterns
local PATTERN_STATIONARY = "stationary"
local PATTERN_LINEAR = "linear"
local PATTERN_CIRCULAR = "circular"
local PATTERN_ERRATIC = "erratic"
local PATTERN_PURSUIT = "pursuit"
local PATTERN_RETREAT = "retreat"

-- Movement thresholds
local MOVEMENT_THRESHOLD = 0.5 -- Minimum distance to consider as movement
local STATIONARY_THRESHOLD = 0.2 -- Maximum movement to consider as stationary
local DIRECTION_CHANGE_THRESHOLD = 30 -- Degrees of change to consider a direction change

-- Analyze movement pattern based on position history
---@param position_history table Array of position entries with x, y, z, time fields
---@return string pattern_name The detected movement pattern
function TankEngine.modules.enemy_tracking.analyze_pathing(position_history)
    if #position_history < 3 then
        return PATTERN_STATIONARY
    end
    
    -- Calculate total distance moved
    local total_distance = 0
    for i = 2, #position_history do
        local prev = position_history[i-1]
        local curr = position_history[i]
        
        local dx = curr.x - prev.x
        local dy = curr.y - prev.y
        local distance = math.sqrt(dx*dx + dy*dy)
        
        total_distance = total_distance + distance
    end
    
    -- Check if mostly stationary
    if total_distance < STATIONARY_THRESHOLD * (#position_history - 1) then
        return PATTERN_STATIONARY
    end
    
    -- Calculate directional changes
    local direction_changes = 0
    local prev_direction = nil
    
    for i = 2, #position_history - 1 do
        local p1 = position_history[i-1]
        local p2 = position_history[i]
        local p3 = position_history[i+1]
        
        -- Calculate vectors
        local v1x, v1y = p2.x - p1.x, p2.y - p1.y
        local v2x, v2y = p3.x - p2.x, p3.y - p2.y
        
        -- Calculate magnitudes
        local mag1 = math.sqrt(v1x*v1x + v1y*v1y)
        local mag2 = math.sqrt(v2x*v2x + v2y*v2y)
        
        -- Skip if not enough movement
        if mag1 < MOVEMENT_THRESHOLD or mag2 < MOVEMENT_THRESHOLD then
            goto continue
        end
        
        -- Normalize vectors
        v1x, v1y = v1x / mag1, v1y / mag1
        v2x, v2y = v2x / mag2, v2y / mag2
        
        -- Calculate dot product
        local dot = v1x * v2x + v1y * v2y
        
        -- Convert to angle (in degrees)
        local angle = math.acos(math.max(-1, math.min(1, dot))) * (180 / math.pi)
        
        -- Check if direction changed significantly
        if angle > DIRECTION_CHANGE_THRESHOLD then
            direction_changes = direction_changes + 1
        end
        
        ::continue::
    end
    
    -- Check movement relative to player
    local first = position_history[1]
    local last = position_history[#position_history]
    local player = TankEngine.variables.me:get_position()
    
    local initial_dist_to_player = math.sqrt((first.x - player.x)^2 + (first.y - player.y)^2)
    local final_dist_to_player = math.sqrt((last.x - player.x)^2 + (last.y - player.y)^2)
    local dist_change = final_dist_to_player - initial_dist_to_player
    
    -- Determine pattern
    if direction_changes >= (#position_history - 2) * 0.5 then
        return PATTERN_ERRATIC
    elseif direction_changes >= (#position_history - 2) * 0.25 then
        return PATTERN_CIRCULAR
    elseif dist_change < -MOVEMENT_THRESHOLD * 2 then
        return PATTERN_PURSUIT
    elseif dist_change > MOVEMENT_THRESHOLD * 2 then
        return PATTERN_RETREAT
    else
        return PATTERN_LINEAR
    end
end

-- Predict future position of an enemy
---@param enemy game_object
---@param time_ahead number Time in seconds to predict ahead
---@return table|nil position Predicted position with x, y, z fields, or nil if prediction failed
function TankEngine.modules.enemy_tracking.predict_position(enemy, time_ahead)
    local module = TankEngine.modules.enemy_tracking
    local data = module.tracked_enemies[enemy]
    
    if not data or not data.pathing_pattern or #data.position_history < 2 then
        return nil
    end
    
    local history = data.position_history
    local pattern = data.pathing_pattern
    local current_pos = enemy:get_position()
    
    -- Get last recorded position and time
    local last = history[#history]
    local prev = history[#history - 1]
    
    -- Calculate time difference
    local dt = (last.time - prev.time) / 1000 -- Convert to seconds
    
    -- If no significant time has passed, can't make prediction
    if dt <= 0.01 then
        return current_pos
    end
    
    -- Calculate current velocity
    local vx = (last.x - prev.x) / dt
    local vy = (last.y - prev.y) / dt
    local vz = (last.z - prev.z) / dt
    
    -- Simple linear prediction for most patterns
    if pattern == PATTERN_LINEAR or pattern == PATTERN_PURSUIT or pattern == PATTERN_RETREAT then
        return {
            x = current_pos.x + vx * time_ahead,
            y = current_pos.y + vy * time_ahead,
            z = current_pos.z + vz * time_ahead
        }
    elseif pattern == PATTERN_STATIONARY then
        return current_pos
    elseif pattern == PATTERN_ERRATIC or pattern == PATTERN_CIRCULAR then
        -- For erratic or circular movement, use a much shorter prediction time
        local adjusted_time = time_ahead * 0.25
        return {
            x = current_pos.x + vx * adjusted_time,
            y = current_pos.y + vy * adjusted_time,
            z = current_pos.z + vz * adjusted_time
        }
    end
    
    -- Fallback
    return current_pos
end

-- Get enemies moving toward the player
---@return game_object[] approaching_enemies
function TankEngine.modules.enemy_tracking.get_approaching_enemies()
    local module = TankEngine.modules.enemy_tracking
    local approaching = {}
    
    for enemy, data in pairs(module.tracked_enemies) do
        if data.pathing_pattern == PATTERN_PURSUIT then
            table.insert(approaching, enemy)
        end
    end
    
    return approaching
end

-- Get enemies moving away from the player
---@return game_object[] retreating_enemies
function TankEngine.modules.enemy_tracking.get_retreating_enemies()
    local module = TankEngine.modules.enemy_tracking
    local retreating = {}
    
    for enemy, data in pairs(module.tracked_enemies) do
        if data.pathing_pattern == PATTERN_RETREAT then
            table.insert(retreating, enemy)
        end
    end
    
    return retreating
end

-- Find optimal position based on enemy movement patterns
---@param preferred_range number Preferred distance to maintain from enemies
---@return table|nil position Optimal position with x, y, z fields, or nil if can't determine
function TankEngine.modules.enemy_tracking.find_optimal_position(preferred_range)
    local module = TankEngine.modules.enemy_tracking
    local me = TankEngine.variables.me
    local my_pos = me:get_position()
    
    -- Default to current position if no enemies or preferred range
    if not preferred_range or preferred_range <= 0 or not next(module.tracked_enemies) then
        return my_pos
    end
    
    -- Calculate average enemy position
    local avg_x, avg_y, avg_z = 0, 0, 0
    local count = 0
    
    for enemy, data in pairs(module.tracked_enemies) do
        if enemy and enemy:is_valid() and not enemy:is_dead() then
            local pos = enemy:get_position()
            avg_x = avg_x + pos.x
            avg_y = avg_y + pos.y
            avg_z = avg_z + pos.z
            count = count + 1
        end
    end
    
    -- No valid enemies
    if count == 0 then
        return my_pos
    end
    
    -- Compute center of enemy mass
    avg_x = avg_x / count
    avg_y = avg_y / count
    avg_z = avg_z / count
    
    -- Calculate direction vector from player to average enemy position
    local dx = avg_x - my_pos.x
    local dy = avg_y - my_pos.y
    local distance = math.sqrt(dx*dx + dy*dy)
    
    -- If already at preferred range, stay put
    if math.abs(distance - preferred_range) < 1.0 then
        return my_pos
    end
    
    -- Normalize direction vector
    if distance > 0 then
        dx = dx / distance
        dy = dy / distance
    else
        -- If at same position, choose random direction
        local angle = math.random() * 2 * math.pi
        dx = math.cos(angle)
        dy = math.sin(angle)
    end
    
    -- Calculate optimal position
    local optimal_x, optimal_y
    
    if distance > preferred_range then
        -- Move closer to enemies
        optimal_x = my_pos.x + dx * (distance - preferred_range)
        optimal_y = my_pos.y + dy * (distance - preferred_range)
    else
        -- Move away from enemies
        optimal_x = my_pos.x - dx * (preferred_range - distance)
        optimal_y = my_pos.y - dy * (preferred_range - distance)
    end
    
    -- Use current Z position (assuming flat terrain for simplicity)
    return {
        x = optimal_x,
        y = optimal_y,
        z = my_pos.z
    }
end

-- Calculate an enemy's speed
---@param enemy game_object
---@return number speed Speed in units per second, or 0 if can't calculate
function TankEngine.modules.enemy_tracking.calculate_enemy_speed(enemy)
    local module = TankEngine.modules.enemy_tracking
    local data = module.tracked_enemies[enemy]
    
    if not data or #data.position_history < 2 then
        return 0
    end
    
    local history = data.position_history
    local last = history[#history]
    local first = history[1]
    
    -- Calculate time difference
    local dt = (last.time - first.time) / 1000 -- Convert to seconds
    
    -- If no significant time has passed, can't calculate speed
    if dt <= 0.01 then
        return 0
    end
    
    -- Calculate distance traveled
    local dx = last.x - first.x
    local dy = last.y - first.y
    local distance = math.sqrt(dx*dx + dy*dy)
    
    -- Calculate speed
    return distance / dt
end

-- Predict enemy movement clusterings
---@param time_ahead number Time in seconds to predict ahead
---@return table|nil cluster Information about predicted enemy cluster
function TankEngine.modules.enemy_tracking.predict_enemy_clustering(time_ahead)
    local module = TankEngine.modules.enemy_tracking
    local clusters = {}
    local cluster_radius = 8 -- Units radius to consider a cluster
    
    -- Predict positions for all enemies
    local predicted_positions = {}
    
    for enemy, data in pairs(module.tracked_enemies) do
        if enemy and enemy:is_valid() and not enemy:is_dead() then
            local predicted_pos = module.predict_position(enemy, time_ahead)
            if predicted_pos then
                predicted_positions[enemy] = predicted_pos
            end
        end
    end
    
    -- Find clusters
    for enemy1, pos1 in pairs(predicted_positions) do
        local cluster = {
            center_x = pos1.x,
            center_y = pos1.y,
            center_z = pos1.z,
            enemies = {enemy1},
            count = 1
        }
        
        -- Check for nearby enemies
        for enemy2, pos2 in pairs(predicted_positions) do
            if enemy1 ~= enemy2 then
                local dx = pos1.x - pos2.x
                local dy = pos1.y - pos2.y
                local distance = math.sqrt(dx*dx + dy*dy)
                
                if distance <= cluster_radius then
                    table.insert(cluster.enemies, enemy2)
                    cluster.count = cluster.count + 1
                    
                    -- Update cluster center
                    cluster.center_x = (cluster.center_x * (cluster.count - 1) + pos2.x) / cluster.count
                    cluster.center_y = (cluster.center_y * (cluster.count - 1) + pos2.y) / cluster.count
                    cluster.center_z = (cluster.center_z * (cluster.count - 1) + pos2.z) / cluster.count
                end
            end
        end
        
        table.insert(clusters, cluster)
    end
    
    -- Sort clusters by enemy count
    table.sort(clusters, function(a, b) return a.count > b.count end)
    
    -- Return largest cluster, or nil if none found
    return #clusters > 0 and clusters[1] or nil
end
