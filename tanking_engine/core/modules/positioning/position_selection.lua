---Calculate position score considering various factors
---@param pos table Position with x, y, z fields
---@param enemies game_object[] Array of enemies to consider
---@param teammates game_object[] Array of teammates to consider
---@return number score Position score (higher is better)
local function calculate_position_score(pos, enemies, teammates)
    local module = TankEngine.modules.positioning
    local settings = module.settings
    local me = TankEngine.variables.me
    local my_pos = me:get_position()
    
    local score = 100 -- Base score
    
    -- Factor 1: Distance from current position (closer is better)
    local distance_from_current = math.sqrt((pos.x - my_pos.x)^2 + (pos.y - my_pos.y)^2)
    score = score - distance_from_current * 2
    
    -- Factor 2: Average distance to enemies (prefer settings.preferred_range)
    local total_enemy_distance = 0
    local enemy_count = 0
    
    for _, enemy in ipairs(enemies) do
        if enemy and enemy:is_valid() and not enemy:is_dead() then
            local enemy_pos = enemy:get_position()
            local dist = math.sqrt((pos.x - enemy_pos.x)^2 + (pos.y - enemy_pos.y)^2)
            total_enemy_distance = total_enemy_distance + dist
            enemy_count = enemy_count + 1
            
            -- Penalty for being too far from any enemy
            if dist > settings.max_range() then
                score = score - 50
            end
            
            -- Bonus for being at preferred range
            local range_diff = math.abs(dist - settings.preferred_range())
            score = score - range_diff * 5
        end
    end
    
    -- Average enemy distance factor
    if enemy_count > 0 then
        local avg_enemy_distance = total_enemy_distance / enemy_count
        local optimal_diff = math.abs(avg_enemy_distance - settings.preferred_range())
        score = score - optimal_diff * 10
    end
    
    -- Factor 3: Line of sight to enemies
    for _, enemy in ipairs(enemies) do
        if enemy and enemy:is_valid() and not enemy:is_dead() then
            local enemy_pos = enemy:get_position()
            -- Simulated line of sight check (actual implementation would depend on game API)
            local has_los = true -- Assume we have LOS for this simulation
            
            if not has_los then
                score = score - 30 -- Significant penalty for not having LOS
            end
        end
    end
    
    -- Factor 4: Distance to teammates (being close to them is generally good)
    local total_teammate_distance = 0
    local teammate_count = 0
    
    for _, teammate in ipairs(teammates) do
        if teammate and teammate:is_valid() and not teammate:is_dead() and teammate ~= me then
            local teammate_pos = teammate:get_position()
            local dist = math.sqrt((pos.x - teammate_pos.x)^2 + (pos.y - teammate_pos.y)^2)
            total_teammate_distance = total_teammate_distance + dist
            teammate_count = teammate_count + 1
        end
    end
    
    -- Average teammate distance factor
    if teammate_count > 0 then
        local avg_teammate_distance = total_teammate_distance / teammate_count
        -- We want to be somewhat close to teammates, but not too close
        local optimal_teammate_distance = 8.0
        local teammate_diff = math.abs(avg_teammate_distance - optimal_teammate_distance)
        score = score - teammate_diff * 3
    end
    
    -- Factor 5: Hazards (to be implemented with actual game mechanics)
    -- For example, checking for void zones, fire, etc.
    
    return score
end

---Generate a grid of potential positions around the player
---@param radius number Radius to consider around the player
---@param step_size number Distance between grid points
---@return table[] positions Array of potential positions
local function generate_position_grid(radius, step_size)
    local positions = {}
    local me = TankEngine.variables.me
    local my_pos = me:get_position()
    
    for x = -radius, radius, step_size do
        for y = -radius, radius, step_size do
            -- Skip if beyond radius
            if x*x + y*y > radius*radius then
                goto continue
            end
            
            table.insert(positions, {
                x = my_pos.x + x,
                y = my_pos.y + y,
                z = my_pos.z -- Assume same Z for simplicity
            })
            
            ::continue::
        end
    end
    
    return positions
end

---Find optimal position for tanking
---@return table|nil position Optimal position with x, y, z fields, or nil if can't determine
function TankEngine.modules.positioning.find_optimal_position()
    local me = TankEngine.variables.me
    
    -- Get all relevant units
    local enemies = TankEngine.variables.nearby_enemies
    local teammates = {}
    
    -- Get teammates from party
    local party_members = core.object_manager.get_all_objects() -- This is inefficient, would need proper filtering
    for _, unit in pairs(party_members) do
        if unit and unit:is_valid() and unit:is_player() and unit:is_party_member() and unit ~= me then
            table.insert(teammates, unit)
        end
    end
    
    -- If no enemies, return current position
    if #enemies == 0 then
        return me:get_position()
    end
    
    -- Generate grid of potential positions
    local positions = generate_position_grid(20, 5) -- 20 unit radius, 5 unit steps
    
    -- Evaluate each position
    local best_position = nil
    local best_score = -1000
    
    for _, pos in ipairs(positions) do
        local score = calculate_position_score(pos, enemies, teammates)
        
        if score > best_score then
            best_position = pos
            best_score = score
        end
    end
    
    return best_position
end

---Find optimal position for AoE tanking
---@param min_enemies number Minimum number of enemies to include
---@param max_range number Maximum range to consider
---@return table|nil position Optimal position with x, y, z fields, or nil if can't determine
function TankEngine.modules.positioning.find_aoe_position(min_enemies, max_range)
    local me = TankEngine.variables.me
    local enemies = TankEngine.variables.nearby_enemies
    
    -- If not enough enemies, return nil
    if #enemies < min_enemies then
        return nil
    end
    
    -- Generate grid of potential positions
    local positions = generate_position_grid(max_range, 5)
    
    -- For each position, count enemies within AoE range
    local best_position = nil
    local max_count = 0
    
    for _, pos in ipairs(positions) do
        local count = 0
        
        for _, enemy in ipairs(enemies) do
            if enemy and enemy:is_valid() and not enemy:is_dead() then
                local enemy_pos = enemy:get_position()
                local dist = math.sqrt((pos.x - enemy_pos.x)^2 + (pos.y - enemy_pos.y)^2)
                
                -- Typical AoE radius of 8 units
                if dist <= 8 then
                    count = count + 1
                end
            end
        end
        
        if count > max_count then
            best_position = pos
            max_count = count
        end
    end
    
    -- Only return position if it meets minimum enemies requirement
    if max_count >= min_enemies then
        return best_position
    else
        return nil
    end
end

---Find optimal position for boss positioning
---@param boss game_object The boss to position
---@param face_away boolean Whether to position with boss facing away from group
---@return table|nil position Optimal position with x, y, z fields, or nil if can't determine
function TankEngine.modules.positioning.find_boss_position(boss, face_away)
    if not boss or not boss:is_valid() or boss:is_dead() then
        return nil
    end
    
    local me = TankEngine.variables.me
    local boss_pos = boss:get_position()
    local teammates = {}
    
    -- Get teammates from party
    local party_members = core.object_manager.get_all_objects() -- This is inefficient, would need proper filtering
    for _, unit in pairs(party_members) do
        if unit and unit:is_valid() and unit:is_player() and unit:is_party_member() and unit ~= me then
            table.insert(teammates, unit)
        end
    end
    
    -- Calculate average position of teammates
    local avg_x, avg_y, avg_z = 0, 0, 0
    local count = 0
    
    for _, teammate in ipairs(teammates) do
        local pos = teammate:get_position()
        avg_x = avg_x + pos.x
        avg_y = avg_y + pos.y
        avg_z = avg_z + pos.z
        count = count + 1
    end
    
    -- If no teammates, use player's position
    if count == 0 then
        avg_x, avg_y, avg_z = me:get_position().x, me:get_position().y, me:get_position().z
    else
        avg_x, avg_y, avg_z = avg_x / count, avg_y / count, avg_z / count
    end
    
    -- Calculate direction vector from average position to boss
    local dx = boss_pos.x - avg_x
    local dy = boss_pos.y - avg_y
    local distance = math.sqrt(dx*dx + dy*dy)
    
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
    
    -- Calculate optimal position based on boss position and tank role
    local optimal_x, optimal_y, optimal_z
    
    if face_away then
        -- Position so boss faces away from group
        -- Place tank on opposite side of boss from group
        optimal_x = boss_pos.x + dx * TankEngine.modules.positioning.settings.preferred_range()
        optimal_y = boss_pos.y + dy * TankEngine.modules.positioning.settings.preferred_range()
        optimal_z = boss_pos.z
    else
        -- Position so boss faces the tank and away from group
        -- Place tank between boss and group
        optimal_x = boss_pos.x - dx * TankEngine.modules.positioning.settings.preferred_range()
        optimal_y = boss_pos.y - dy * TankEngine.modules.positioning.settings.preferred_range()
        optimal_z = boss_pos.z
    end
    
    return {
        x = optimal_x,
        y = optimal_y,
        z = optimal_z
    }
end

---Find safe position to retreat to
---@return table|nil position Safe position with x, y, z fields, or nil if can't determine
function TankEngine.modules.positioning.find_safe_retreat_position()
    local me = TankEngine.variables.me
    local my_pos = me:get_position()
    local enemies = TankEngine.variables.nearby_enemies
    local teammates = {}
    
    -- Get teammates from party
    local party_members = core.object_manager.get_all_objects() -- This is inefficient, would need proper filtering
    for _, unit in pairs(party_members) do
        if unit and unit:is_valid() and unit:is_player() and unit:is_party_member() and unit ~= me then
            table.insert(teammates, unit)
        end
    end
    
    -- Calculate average position of teammates (this will be our retreat direction)
    local avg_x, avg_y, avg_z = 0, 0, 0
    local count = 0
    
    for _, teammate in ipairs(teammates) do
        local pos = teammate:get_position()
        avg_x = avg_x + pos.x
        avg_y = avg_y + pos.y
        avg_z = avg_z + pos.z
        count = count + 1
    end
    
    -- If no teammates, retreat in opposite direction of nearest enemy
    if count == 0 then
        local nearest_enemy = nil
        local min_distance = 1000000
        
        for _, enemy in ipairs(enemies) do
            if enemy and enemy:is_valid() and not enemy:is_dead() then
                local enemy_pos = enemy:get_position()
                local dist = math.sqrt((my_pos.x - enemy_pos.x)^2 + (my_pos.y - enemy_pos.y)^2)
                
                if dist < min_distance then
                    nearest_enemy = enemy
                    min_distance = dist
                end
            end
        end
        
        if nearest_enemy then
            local enemy_pos = nearest_enemy:get_position()
            -- Direction away from enemy
            avg_x = my_pos.x * 2 - enemy_pos.x
            avg_y = my_pos.y * 2 - enemy_pos.y
            avg_z = my_pos.z
        else
            -- No enemies, no need to retreat
            return nil
        end
    else
        avg_x, avg_y, avg_z = avg_x / count, avg_y / count, avg_z / count
    end
    
    -- Calculate direction vector from player to retreat position
    local dx = avg_x - my_pos.x
    local dy = avg_y - my_pos.y
    local distance = math.sqrt(dx*dx + dy*dy)
    
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
    
    -- Calculate retreat path
    local retreat_distance = TankEngine.modules.positioning.settings.kiting_distance()
    
    return {
        x = my_pos.x + dx * retreat_distance,
        y = my_pos.y + dy * retreat_distance,
        z = my_pos.z
    }
end
