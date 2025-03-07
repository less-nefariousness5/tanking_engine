-- Utility functions for the Tanking Engine

-- Directly require the enums to avoid circular dependency
local api_enums = require("common/enums")
local tank_enums = require("shared/tank_enums")

-- Combine enums
local enums = {}
for k, v in pairs(api_enums) do
    enums[k] = v
end
for k, v in pairs(tank_enums) do
    enums[k] = v
end

local Utils = {}

-- Check if a spell is available to cast (known, not on cooldown, has resources)
---@param spell_id number The ID of the spell to check
---@return boolean is_available Whether the spell is available to cast
function Utils.can_cast_spell(spell_id)
    if not spell_id then
        return false
    end
    
    -- Check if the spell exists in the spellbook
    if not core.spell_book.has_spell(spell_id) then
        return false
    end
    
    -- Check if the spell is usable (has resources, etc.)
    if not core.spell_book.is_usable_spell(spell_id) then
        return false
    end
    
    -- Check if the spell is on cooldown
    local cooldown = core.spell_book.get_spell_cooldown(spell_id)
    if cooldown and cooldown > 0 then
        return false
    end
    
    return true
end

-- Calculate the threat level of an enemy
---@param unit game_object The enemy unit to check
---@return number threat_level The threat level (from enums.threat_level)
function Utils.calculate_threat_level(unit)
    if not unit or not unit:is_valid() then
        return enums.threat_level.LOW
    end
    
    -- Check if the unit is targeting us
    local local_player = core.object_manager.get_local_player()
    if not local_player then
        return enums.threat_level.LOW
    end
    
    local unit_target = unit:get_target()
    if not unit_target or not unit_target:is_valid() then
        return enums.threat_level.LOW
    end
    
    -- If the unit is targeting us, it's a high threat
    if unit_target:get_guid() == local_player:get_guid() then
        return enums.threat_level.HIGH
    end
    
    -- If the unit is targeting another player, it's a critical threat
    if unit_target:is_player() then
        return enums.threat_level.CRITICAL
    end
    
    -- Otherwise, it's a medium threat
    return enums.threat_level.MEDIUM
end

-- Get all enemies in combat with the player
---@param range number Optional range to check (defaults to 40)
---@return table enemies List of enemy units in combat
function Utils.get_enemies_in_combat(range)
    range = range or 40
    local enemies = {}
    local local_player = core.object_manager.get_local_player()
    
    if not local_player then
        return enemies
    end
    
    local units = core.object_manager.get_all_objects()
    for _, unit in ipairs(units) do
        if unit:is_valid() and unit:is_unit() and unit:is_enemy() and unit:is_in_combat() and 
           local_player:get_position():dist_to(unit:get_position()) <= range then
            table.insert(enemies, unit)
        end
    end
    
    return enemies
end

-- Get all party/raid members
---@param include_self boolean Whether to include the player in the results
---@return table group_members List of group member units
function Utils.get_group_members(include_self)
    local group_members = {}
    local local_player = core.object_manager.get_local_player()
    
    if not local_player then
        return group_members
    end
    
    if include_self then
        table.insert(group_members, local_player)
    end
    
    local units = core.object_manager.get_all_objects()
    for _, unit in ipairs(units) do
        if unit:is_valid() and unit:is_player() and unit:get_guid() ~= local_player:get_guid() and 
           (unit:is_in_party() or unit:is_in_raid()) then
            table.insert(group_members, unit)
        end
    end
    
    return group_members
end

-- Check if a defensive cooldown should be used based on health percentage
---@param health_percent number Current health percentage (0-100)
---@param threshold number Health threshold to trigger the cooldown
---@param enemy_count number Number of enemies in combat
---@param is_boss boolean Whether fighting a boss
---@return boolean should_use Whether the cooldown should be used
function Utils.should_use_defensive_cooldown(health_percent, threshold, enemy_count, is_boss)
    -- Base case: health below threshold
    if health_percent <= threshold then
        return true
    end
    
    -- Adjust threshold based on number of enemies
    local adjusted_threshold = threshold
    if enemy_count > 3 then
        adjusted_threshold = adjusted_threshold + 10
    end
    
    -- Adjust threshold for boss fights
    if is_boss then
        adjusted_threshold = adjusted_threshold + 5
    end
    
    return health_percent <= adjusted_threshold
end

-- Get the best target to taunt based on threat analysis
---@param enemies table List of enemy units
---@return game_object|nil target The best target to taunt, or nil if none
function Utils.get_best_taunt_target(enemies)
    if not enemies or #enemies == 0 then
        return nil
    end
    
    local best_target = nil
    local highest_priority = 0
    
    for _, enemy in ipairs(enemies) do
        if enemy:is_valid() then
            local threat_level = Utils.calculate_threat_level(enemy)
            local target = enemy:get_target()
            
            -- Prioritize enemies targeting non-tanks
            local priority = 0
            if target and target:is_valid() and target:is_player() then
                local role = target:get_role()
                if role ~= enums.group_role.TANK then
                    priority = threat_level * 2
                else
                    priority = threat_level
                end
            end
            
            if priority > highest_priority then
                highest_priority = priority
                best_target = enemy
            end
        end
    end
    
    return best_target
end

-- Calculate the optimal position for tanking
---@param enemies table List of enemy units
---@param strategy number The positioning strategy to use
---@return number x, number y, number z The optimal position coordinates
function Utils.calculate_optimal_position(enemies, strategy)
    local local_player = core.object_manager.get_local_player()
    if not local_player or not enemies or #enemies == 0 then
        return 0, 0, 0
    end
    
    local player_x, player_y, player_z = local_player:get_position()
    
    -- Default to current position
    local optimal_x, optimal_y, optimal_z = player_x, player_y, player_z
    
    if strategy == enums.positioning_strategy.STATIONARY then
        -- Stay in current position
        return optimal_x, optimal_y, optimal_z
        
    elseif strategy == enums.positioning_strategy.GATHERING then
        -- Calculate center position of all enemies
        local sum_x, sum_y, sum_z = 0, 0, 0
        for _, enemy in ipairs(enemies) do
            if enemy:is_valid() then
                local x, y, z = enemy:get_position()
                sum_x = sum_x + x
                sum_y = sum_y + y
                sum_z = sum_z + z
            end
        end
        
        optimal_x = sum_x / #enemies
        optimal_y = sum_y / #enemies
        optimal_z = sum_z / #enemies
        
    elseif strategy == enums.positioning_strategy.KITING then
        -- Move away from enemies while keeping them in range
        local closest_enemy = nil
        local closest_distance = 999999
        
        for _, enemy in ipairs(enemies) do
            if enemy:is_valid() then
                local distance = local_player:get_position():dist_to(enemy:get_position())
                if distance < closest_distance then
                    closest_distance = distance
                    closest_enemy = enemy
                end
            end
        end
        
        if closest_enemy then
            local enemy_x, enemy_y, enemy_z = closest_enemy:get_position()
            local direction_x = player_x - enemy_x
            local direction_y = player_y - enemy_y
            
            -- Normalize direction vector
            local length = math.sqrt(direction_x * direction_x + direction_y * direction_y)
            if length > 0 then
                direction_x = direction_x / length
                direction_y = direction_y / length
                
                -- Move 10 yards in the opposite direction of the closest enemy
                optimal_x = player_x + direction_x * 10
                optimal_y = player_y + direction_y * 10
                optimal_z = player_z
            end
        end
    end
    
    return optimal_x, optimal_y, optimal_z
end

return Utils
