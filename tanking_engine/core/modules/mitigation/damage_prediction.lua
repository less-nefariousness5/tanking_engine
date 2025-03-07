---Update damage prediction model
function TankEngine.modules.mitigation.update_damage_prediction()
    local module = TankEngine.modules.mitigation
    
    -- Reset prediction values
    module.predicted_health_loss = 0
    module.predicted_spike_incoming = false
    
    -- Only predict if we have enough history
    if #module.damage_history < 3 then
        return
    end
    
    -- Identify damage patterns
    local recent_window = 1500 -- Look at damage in last 1.5 seconds
    local window_start = core.game_time() - recent_window
    local recent_damage = 0
    local damage_count = 0
    local max_single_hit = 0
    
    for i = #module.damage_history, 1, -1 do
        local event = module.damage_history[i]
        if event.timestamp >= window_start then
            recent_damage = recent_damage + event.amount
            damage_count = damage_count + 1
            max_single_hit = math.max(max_single_hit, event.amount)
        else
            break -- Damage history is chronological, so we can stop once we're out of the window
        end
    end
    
    -- Calculate average damage per hit in recent window
    local avg_damage_per_hit = damage_count > 0 and (recent_damage / damage_count) or 0
    
    -- Analyze damage patterns
    local me = TankEngine.variables.me
    local max_health = me:get_max_health()
    
    -- Detect potential spike damage
    local is_spike_pattern = false
    
    -- Pattern 1: Large single hit recently
    if max_single_hit > max_health * 0.15 then
        is_spike_pattern = true
    end
    
    -- Pattern 2: Increasing damage trend
    if damage_count >= 3 then
        local first_half_damage = 0
        local second_half_damage = 0
        local half_count = math.floor(damage_count / 2)
        
        for i = #module.damage_history - damage_count + 1, #module.damage_history - half_count do
            first_half_damage = first_half_damage + module.damage_history[i].amount
        end
        
        for i = #module.damage_history - half_count + 1, #module.damage_history do
            second_half_damage = second_half_damage + module.damage_history[i].amount
        end
        
        -- If second half damage is significantly higher than first half
        if second_half_damage > first_half_damage * 1.5 then
            is_spike_pattern = true
        end
    end
    
    -- Pattern 3: High sustained damage rate
    if damage_count >= 2 and recent_damage > max_health * 0.25 then
        is_spike_pattern = true
    end
    
    -- Calculate predicted health loss in next few seconds
    local prediction_window = 3.0 -- Predict damage for next 3 seconds
    local predicted_loss = 0
    
    if damage_count > 0 then
        -- Base prediction on recent DPS
        local recent_dps = recent_damage / (recent_window / 1000)
        predicted_loss = recent_dps * prediction_window
        
        -- Adjust prediction based on pattern analysis
        if is_spike_pattern then
            predicted_loss = predicted_loss * 1.5 -- Increase prediction if spike pattern detected
        end
    end
    
    -- Update prediction results
    module.predicted_health_loss = predicted_loss
    module.predicted_spike_incoming = is_spike_pattern
end

---Check if dangerous cast is incoming from any enemy
---@return boolean
function TankEngine.modules.mitigation.is_dangerous_cast_incoming()
    for _, enemy in ipairs(TankEngine.variables.nearby_enemies) do
        if enemy and enemy:is_valid() and not enemy:is_dead() and enemy:is_casting_spell() then
            local spell = enemy:get_current_cast_spell()
            
            -- Skip if no spell info
            if not spell then
                goto continue
            end
            
            -- Placeholder for dangerous spell detection
            -- TODO: Implement logic to check if spell is dangerous
            local is_dangerous = false
            
            if is_dangerous then
                return true
            end
        end
        
        ::continue::
    end
    
    return false
end

---Get a prediction of incoming damage
---@return number predicted_damage Predicted damage as percentage of max health
---@return boolean is_spike Whether a damage spike is predicted
function TankEngine.modules.mitigation.get_damage_prediction()
    local module = TankEngine.modules.mitigation
    local me = TankEngine.variables.me
    
    if not me or not me:is_valid() then
        return 0, false
    end
    
    local max_health = me:get_max_health()
    local damage_percent = module.predicted_health_loss / max_health
    
    return damage_percent, module.predicted_spike_incoming
end
