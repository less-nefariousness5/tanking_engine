---Calculate estimated threat value for an enemy
---@param enemy game_object
---@return number threat_value
function TankEngine.modules.threat_manager.calculate_threat_value(enemy)
    local threat_value = 50 -- base threat value
    
    -- Adjust based on health
    local health_pct = enemy:get_health() / enemy:get_max_health()
    threat_value = threat_value + (1 - health_pct) * 10 -- lower health = higher threat
    
    -- Adjust based on enemy level/classification
    local classification = enemy:get_classification()
    if classification == 1 then -- ELITE
        threat_value = threat_value + 15
    end
    
    if classification == 4 then -- RARE
        threat_value = threat_value + 10
    end
    
    if classification == 2 then -- RARE_ELITE
        threat_value = threat_value + 20
    end
    
    if classification == 3 then -- WORLD_BOSS
        threat_value = threat_value + 30
    end
    
    -- Adjust based on distance (closer = higher threat)
    local distance = TankEngine.variables.me:get_position():dist_to(enemy:get_position())
    local distance_factor = math.min(1, 40 / math.max(1, distance))
    threat_value = threat_value + distance_factor * 15
    
    -- Check if enemy is casting
    if enemy:is_casting_spell() then
        threat_value = threat_value + 20
    end
    
    -- Normalize to 0-100 range
    return math.min(100, math.max(0, threat_value))
end

---Calculate taunt priority for an enemy
---@param enemy game_object
---@param is_targeting_tank boolean
---@param is_targeting_healer boolean
---@param is_targeting_dps boolean
---@return number taunt_priority
function TankEngine.modules.threat_manager.calculate_taunt_priority(enemy, is_targeting_tank, is_targeting_healer, is_targeting_dps)
    local module = TankEngine.modules.threat_manager
    local priority = 0
    
    -- Base priority is the threat value
    priority = module.calculate_threat_value(enemy)
    
    -- Adjust based on target
    if is_targeting_tank then
        -- Already targeting a tank, low priority
        priority = priority * 0.3
    elseif is_targeting_healer then
        -- Targeting a healer, highest priority
        priority = priority * 2.0
    elseif is_targeting_dps then
        -- Targeting DPS, medium-high priority
        priority = priority * 1.5
    else
        -- Not targeting anyone, medium priority
        priority = priority * 0.8
    end
    
    -- Check time since last taunt
    local time_since_taunt = core.game_time() - (module.taunt_history[enemy] or 0)
    if time_since_taunt < 10000 then -- 10 seconds
        -- Reduce priority for recently taunted targets
        priority = priority * (time_since_taunt / 10000)
    end
    
    -- Adjust by enemy level/classification
    local classification = enemy:get_classification()
    if classification == 1 then -- ELITE
        priority = priority * 1.5
    end
    
    if classification == 4 then -- RARE
        priority = priority * 1.0
    end
    
    if classification == 2 then -- RARE_ELITE
        priority = priority * 2.0
    end
    
    if classification == 3 then -- WORLD_BOSS
        priority = priority * 3.0
    end
    
    -- Adjust by distance (closer enemies have higher priority)
    local distance = TankEngine.variables.me:get_position():dist_to(enemy:get_position())
    if distance < 10 then
        priority = priority * 1.2
    elseif distance > 30 then
        priority = priority * 0.7
    end
    
    -- Adjust by current health percentage (lower health = lower priority)
    local health_pct = enemy:get_health() / enemy:get_max_health()
    if health_pct < 0.2 then -- Below 20% health
        priority = priority * 0.5
    end
    
    -- Prioritize loose mobs if enabled
    if module.settings.prioritize_loose_mobs() and not is_targeting_tank then
        priority = priority * 1.3
    end
    
    return priority
end
