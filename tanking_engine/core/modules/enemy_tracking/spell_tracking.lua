-- Register a spell as dangerous
---@param spell_id number
---@param interrupt_priority number Priority for interruption (1-100, higher = more important)
function TankEngine.modules.enemy_tracking.register_dangerous_spell(spell_id, interrupt_priority)
    TankEngine.modules.enemy_tracking.dangerous_spells[spell_id] = true
    TankEngine.modules.enemy_tracking.interrupt_priorities[spell_id] = interrupt_priority or 50
end

-- Check if a spell is registered as dangerous
---@param spell_id number
---@return boolean
function TankEngine.modules.enemy_tracking.is_dangerous_spell(spell_id)
    return TankEngine.modules.enemy_tracking.dangerous_spells[spell_id] or false
end

-- Get interrupt priority for a spell
---@param spell_id number
---@return number Priority (0-100, higher = more important)
function TankEngine.modules.enemy_tracking.get_interrupt_priority(spell_id)
    return TankEngine.modules.enemy_tracking.interrupt_priorities[spell_id] or 0
end

-- Initialize default dangerous spell list
function TankEngine.modules.enemy_tracking.init_dangerous_spells()
    -- This would be filled with known dangerous dungeon and raid spell IDs
    -- For example:
    -- TankEngine.modules.enemy_tracking.register_dangerous_spell(12345, 90) -- High priority dangerous spell
    -- TankEngine.modules.enemy_tracking.register_dangerous_spell(67890, 60) -- Medium priority dangerous spell
end

-- Find the highest priority interrupt target
---@param spell_id number ID of the interrupt spell to check castability
---@param skip_facing boolean Whether to skip facing requirement check
---@param skip_range boolean Whether to skip range requirement check
---@param min_priority number Minimum priority to consider for interruption
---@return game_object|nil target The highest priority interrupt target, or nil if none found
function TankEngine.modules.enemy_tracking.get_highest_priority_interrupt(spell_id, skip_facing, skip_range, min_priority)
    local module = TankEngine.modules.enemy_tracking
    local best_target = nil
    local best_priority = min_priority or 0
    
    for enemy, data in pairs(module.tracked_enemies) do
        -- Skip if enemy is not casting or cast is not interruptible
        if not data.current_cast or not data.current_cast.interruptible then
            goto continue
        end
        
        -- Check if priority is high enough
        if data.interrupt_priority <= best_priority then
            goto continue
        end
        
        -- Check if interrupt spell is castable on this target
        if not TankEngine.api.spell_helper:is_spell_queueable(spell_id, TankEngine.variables.me, enemy, skip_facing, skip_range) then
            goto continue
        end
        
        best_target = enemy
        best_priority = data.interrupt_priority
        
        ::continue::
    end
    
    return best_target
end

-- Find all enemies casting dangerous spells
---@return table<game_object, {spell_id: number, priority: number, time_remaining: number}>
function TankEngine.modules.enemy_tracking.get_dangerous_casters()
    local module = TankEngine.modules.enemy_tracking
    local dangerous_casters = {}
    
    for enemy, data in pairs(module.tracked_enemies) do
        if data.current_cast and data.current_cast.is_dangerous then
            dangerous_casters[enemy] = {
                spell_id = data.current_cast.spell_id,
                priority = data.current_cast.priority,
                time_remaining = data.current_cast.end_time - core.game_time()
            }
        end
    end
    
    return dangerous_casters
end

-- Check if an enemy has a specific ability on cooldown
---@param enemy game_object
---@param ability_id number
---@return boolean
---@return number remaining Remaining cooldown time in ms, or 0 if not on cooldown
function TankEngine.modules.enemy_tracking.is_ability_on_cooldown(enemy, ability_id)
    local module = TankEngine.modules.enemy_tracking
    local data = module.tracked_enemies[enemy]
    
    if not data then
        return false, 0
    end
    
    local cooldown_end = data.cooldowns[ability_id]
    
    if not cooldown_end then
        return false, 0
    end
    
    local current_time = core.game_time()
    
    if cooldown_end > current_time then
        return true, cooldown_end - current_time
    else
        -- Clean up expired cooldown
        data.cooldowns[ability_id] = nil
        return false, 0
    end
end

-- Register an ability use by an enemy
---@param enemy game_object
---@param ability_id number
---@param cooldown number Cooldown duration in milliseconds
function TankEngine.modules.enemy_tracking.register_ability_use(enemy, ability_id, cooldown)
    local module = TankEngine.modules.enemy_tracking
    local data = module.tracked_enemies[enemy]
    
    if not data then
        return
    end
    
    local current_time = core.game_time()
    data.cooldowns[ability_id] = current_time + cooldown
end

-- Get all interruptible casts
---@return table<game_object, {spell_id: number, priority: number, time_remaining: number}>
function TankEngine.modules.enemy_tracking.get_interruptible_casts()
    local module = TankEngine.modules.enemy_tracking
    local interruptible_casts = {}
    
    for enemy, data in pairs(module.tracked_enemies) do
        if data.current_cast and data.current_cast.interruptible then
            interruptible_casts[enemy] = {
                spell_id = data.current_cast.spell_id,
                priority = data.current_cast.priority,
                time_remaining = data.current_cast.end_time - core.game_time()
            }
        end
    end
    
    return interruptible_casts
end
