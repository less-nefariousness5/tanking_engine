---@diagnostic disable: missing-fields

---@type buff_manager
local buff_manager = require("common/modules/buff_manager")
---@type vec3
local vec3 = require("common/geometry/vector_3")

-- Global variables for the tanking engine
TankEngine.variables = {
    ---@type game_object
    me = core.object_manager.get_local_player(),
    
    ---@type fun(): game_object?
    target = function() 
        local me = TankEngine.variables.me
        if not me or not me:is_valid() then return nil end
        local success, result = pcall(function() return me:get_target() end)
        if success and result then
            return result
        end
        return nil
    end,
    
    ---@type fun(): game_object?
    enemy_target = function() 
        if not TankEngine.variables.is_valid_enemy_target() then 
            return nil 
        end
        
        local me = TankEngine.variables.me
        if not me or not me:is_valid() then 
            return nil 
        end
        
        local success, result = pcall(function() return me:get_target() end)
        if success and result and result:is_valid() then
            return result
        end
        
        return nil 
    end,
    
    ---@type fun(): boolean
    is_valid_enemy_target = function()
        local target = TankEngine.variables.target()
        if not target then return false end
        if not target:is_valid() then return false end
        
        local is_dead = false
        local success, result = pcall(function() return target:is_dead() end)
        if success then is_dead = result end
        if is_dead then return false end
        
        local me = TankEngine.variables.me
        if not me or not me:is_valid() then return false end
        
        local can_attack = false
        success, result = pcall(function() return me:can_attack(target) end)
        if success then can_attack = result end
        if not can_attack then return false end
        
        return true
    end,
    
    -- Track nearby enemies
    ---@type game_object[]
    nearby_enemies = {},
    
    -- Track enemies targeting group members
    ---@type table<game_object, game_object>
    enemy_targets = {}, -- Maps enemy -> their target
    
    -- Track threatening enemies
    ---@type game_object[]
    threatening_enemies = {},
    
    -- Tank mitigation tracking
    active_mitigation = false,
    mitigation_expires = 0,
}

-- Safe getter for target to prevent nil reference errors
---@return game_object|nil
function TankEngine.variables.get_safe_target()
    local me = TankEngine.variables.me
    if not me or not me:is_valid() then return nil end
    
    -- Handle target as either a function or direct reference
    local target = nil
    if TankEngine.variables.target then
        if type(TankEngine.variables.target) == "function" then
            -- Safely call the function
            local success, result = pcall(TankEngine.variables.target)
            if success and result and result:is_valid() then
                target = result
            end
        else
            -- Direct reference
            target = TankEngine.variables.target
        end
    end
    
    -- Validate target
    if target and target:is_valid() and not target:is_dead() then
        return target
    end
    
    return nil
end

---Calculate the distance between two game objects
---@param obj1 game_object The first game object
---@param obj2 game_object The second game object
---@return number The distance in yards between the two objects
function TankEngine.variables.get_distance_to(obj1, obj2)
    if not obj1 or not obj2 or not obj1:is_valid() or not obj2:is_valid() then
        return 999999 -- Return a large number if either object is invalid
    end
    
    local pos1 = obj1:get_position()
    local pos2 = obj2:get_position()
    
    return pos1:dist_to(pos2)
end

---Calculate the distance between a game object and a position
---@param obj game_object The game object
---@param position vec3 The position
---@return number The distance in yards between the object and the position
function TankEngine.variables.get_distance_to_position(obj, position)
    if not obj or not obj:is_valid() or not position then
        return 999999 -- Return a large number if the object is invalid
    end
    
    local pos = obj:get_position()
    return pos:dist_to(position)
end

---Check if a buff is active on a unit
---@param spell_id number
---@param unit? game_object
---@return boolean
function TankEngine.variables.buff_up(spell_id, unit)
    unit = unit or TankEngine.variables.me
    if not unit or not unit:is_valid() or unit:is_dead() then return false end
    return buff_manager:get_buff_data(unit, { spell_id }).is_active
end

---Get the remaining time on a buff in milliseconds
---@param spell_id number
---@param unit? game_object
---@return number
function TankEngine.variables.buff_remains(spell_id, unit)
    if not unit or not unit:is_valid() or unit:is_dead() then return 0 end
    unit = unit or TankEngine.variables.me
    return buff_manager:get_buff_data(unit, { spell_id }).remaining
end

---Get the number of stacks of a buff
---@param spell_id number
---@param unit? game_object
---@return number
function TankEngine.variables.buff_stacks(spell_id, unit)
    if not unit or not unit:is_valid() or unit:is_dead() then return 0 end
    unit = unit or TankEngine.variables.me
    return buff_manager:get_buff_data(unit, { spell_id }).stacks
end

---Check if an aura (typically a self-buff) is active
---@param spell_id number
---@return boolean
function TankEngine.variables.aura_up(spell_id)
    return buff_manager:get_aura_data(TankEngine.variables.me, { spell_id }).is_active
end

---Get the remaining time on an aura in milliseconds
---@param spell_id number
---@return number
function TankEngine.variables.aura_remains(spell_id)
    return buff_manager:get_aura_data(TankEngine.variables.me, { spell_id }).remaining
end

---Get the current resource value
---@param power_type number
---@return number
function TankEngine.variables.resource(power_type)
    return TankEngine.variables.me:get_power(power_type)
end

-- Update nearby enemies list
function TankEngine.variables.update_nearby_enemies()
    TankEngine.variables.nearby_enemies = {}
    local objects = core.object_manager.get_all_objects()
    
    for _, obj in ipairs(objects) do
        if obj and obj:is_valid() and not obj:is_dead() and obj:is_unit() and 
           TankEngine.variables.me:can_attack(obj) and
           TankEngine.variables.get_distance_to(TankEngine.variables.me, obj) <= 40 then
            table.insert(TankEngine.variables.nearby_enemies, obj)
        end
    end
    
    -- Sort by distance
    table.sort(TankEngine.variables.nearby_enemies, function(a, b)
        local dist_a = TankEngine.variables.get_distance_to(TankEngine.variables.me, a)
        local dist_b = TankEngine.variables.get_distance_to(TankEngine.variables.me, b)
        return dist_a < dist_b
    end)
end

-- Update enemy targets mapping
function TankEngine.variables.update_enemy_targets()
    TankEngine.variables.enemy_targets = {}
    TankEngine.variables.threatening_enemies = {}
    
    for _, enemy in ipairs(TankEngine.variables.nearby_enemies) do
        local enemy_target = enemy:get_target()
        
        if enemy_target and enemy_target:is_valid() then
            TankEngine.variables.enemy_targets[enemy] = enemy_target
            
            -- If enemy is targeting someone other than the tank, add to threatening list
            if enemy_target ~= TankEngine.variables.me and enemy_target:is_player() then
                table.insert(TankEngine.variables.threatening_enemies, enemy)
            end
        end
    end
    
    -- Sort threatening enemies by health (higher health = higher priority)
    table.sort(TankEngine.variables.threatening_enemies, function(a, b)
        return a:get_health() > b:get_health()
    end)
end

-- Check if active mitigation is currently up
function TankEngine.variables.is_active_mitigation_up()
    return TankEngine.variables.active_mitigation and 
           core.game_time() < TankEngine.variables.mitigation_expires
end

-- Set active mitigation status
---@param duration number Duration in milliseconds
function TankEngine.variables.set_active_mitigation(duration)
    TankEngine.variables.active_mitigation = true
    TankEngine.variables.mitigation_expires = core.game_time() + duration
end
