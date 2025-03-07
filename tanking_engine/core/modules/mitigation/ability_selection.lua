---Get the best available minor defensive ability
---@return MitigationData|nil best_ability
function TankEngine.modules.mitigation.get_best_minor_defensive()
    local module = TankEngine.modules.mitigation
    local best_ability = nil
    local best_priority = 0
    
    for _, ability in pairs(module.abilities) do
        -- Skip major cooldowns
        if ability.is_major then
            goto continue
        end
        
        -- Skip if on cooldown or not available
        if not ability.is_available() then
            goto continue
        end
        
        -- Skip if last used too recently
        if ability.last_used + ability.cooldown > core.game_time() then
            goto continue
        end
        
        -- Compare priority
        if ability.priority > best_priority then
            best_ability = ability
            best_priority = ability.priority
        end
        
        ::continue::
    end
    
    return best_ability
end

---Get the best available major defensive ability
---@return MitigationData|nil best_ability
function TankEngine.modules.mitigation.get_best_major_defensive()
    local module = TankEngine.modules.mitigation
    local best_ability = nil
    local best_priority = 0
    
    for _, ability in pairs(module.abilities) do
        -- Skip non-major cooldowns
        if not ability.is_major then
            goto continue
        end
        
        -- Skip if on cooldown or not available
        if not ability.is_available() then
            goto continue
        end
        
        -- Skip if last used too recently
        if ability.last_used + ability.cooldown > core.game_time() then
            goto continue
        end
        
        -- Compare priority
        if ability.priority > best_priority then
            best_ability = ability
            best_priority = ability.priority
        end
        
        ::continue::
    end
    
    return best_ability
end

---Find the best defensive ability for current situation
---@param health_pct number Current health percentage
---@param damage_prediction number Predicted damage as percentage of max health
---@param is_spike boolean Whether a damage spike is predicted
---@return MitigationData|nil best_ability
function TankEngine.modules.mitigation.get_situational_defensive(health_pct, damage_prediction, is_spike)
    local module = TankEngine.modules.mitigation
    
    -- Decide what type of defensive we need
    local need_major = health_pct <= module.settings.major_cooldown_threshold() or 
                       (health_pct - damage_prediction <= module.settings.major_cooldown_threshold())
    
    if need_major then
        return module.get_best_major_defensive()
    else
        return module.get_best_minor_defensive()
    end
end

---Check if a specific defensive ability should be used
---@param spell_id number The spell ID to check
---@return boolean should_use Whether the ability should be used
function TankEngine.modules.mitigation.should_use_defensive(spell_id)
    local module = TankEngine.modules.mitigation
    local ability = module.abilities[spell_id]
    
    -- If ability not registered, return false
    if not ability then
        return false
    end
    
    -- Check if ability is on cooldown
    if not ability.is_available() or (ability.last_used + ability.cooldown > core.game_time()) then
        return false
    end
    
    -- Get current health percentage
    local health_pct = module.current_health_pct
    
    -- If heal awareness is enabled, use enhanced decision making
    if module.settings.consider_incoming_heals() then
        return module.should_use_defensive_with_heal_awareness(
            spell_id,
            ability.health_threshold,
            ability.is_major
        )
    end
    
    -- Standard logic without heal awareness
    
    -- Check health threshold
    if health_pct <= ability.health_threshold then
        return true
    end
    
    -- Check for predicted damage
    if module.settings.predictive_mitigation() then
        local predicted_damage, is_spike = module.get_damage_prediction()
        
        -- If spike predicted and this is a major cooldown
        if is_spike and ability.is_major then
            return true
        end
        
        -- If health would drop below threshold after predicted damage
        if health_pct - predicted_damage <= ability.health_threshold then
            return true
        end
    end
    
    -- Check active mitigation overlap
    if not ability.is_major and TankEngine.variables.is_active_mitigation_up() then
        -- Calculate remaining percentage of active mitigation
        local current_time = core.game_time()
        local expires = TankEngine.variables.mitigation_expires
        local remaining = math.max(0, expires - current_time)
        
        -- Calculate overlap threshold
        local overlap_threshold = ability.duration * module.settings.active_mitigation_overlap()
        
        -- Refresh if remaining time is less than threshold
        if remaining <= overlap_threshold then
            return true
        end
    end
    
    return false
end

---Check if player has any active defensive
---@return boolean has_active_defensive
---@return MitigationData|nil active_ability
function TankEngine.modules.mitigation.has_active_defensive()
    local current_time = core.game_time()
    
    for _, ability in pairs(TankEngine.modules.mitigation.abilities) do
        -- Calculate when ability effect would expire if used
        local effect_end_time = ability.last_used + ability.duration
        
        -- Check if still active
        if current_time < effect_end_time then
            return true, ability
        end
    end
    
    return false, nil
end

---Get all available defensive abilities
---@return MitigationData[] available_abilities
function TankEngine.modules.mitigation.get_available_defensives()
    local available = {}
    
    for _, ability in pairs(TankEngine.modules.mitigation.abilities) do
        if ability.is_available() and (ability.last_used + ability.cooldown <= core.game_time()) then
            table.insert(available, ability)
        end
    end
    
    -- Sort by priority (highest first)
    table.sort(available, function(a, b)
        return a.priority > b.priority
    end)
    
    return available
end

---Get defensive ability by name
---@param name string The name of the ability
---@return MitigationData|nil ability
function TankEngine.modules.mitigation.get_ability_by_name(name)
    for _, ability in pairs(TankEngine.modules.mitigation.abilities) do
        if ability.name == name then
            return ability
        end
    end
    
    return nil
end

---Get defensive ability by spell ID
---@param spell_id number The spell ID
---@return MitigationData|nil ability
function TankEngine.modules.mitigation.get_ability(spell_id)
    return TankEngine.modules.mitigation.abilities[spell_id]
end
