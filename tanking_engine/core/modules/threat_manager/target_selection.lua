---Get highest threat enemy that's not targeting tank
---@param spell_id number ID of the taunt spell to check castability
---@param skip_facing boolean Whether to skip facing requirement
---@param skip_range boolean Whether to skip range requirement
---@return game_object|nil target The highest priority taunt target or nil
function TankEngine.modules.threat_manager.get_taunt_target(spell_id, skip_facing, skip_range)
    local module = TankEngine.modules.threat_manager
    
    -- Validate parameters
    if not spell_id then
        return nil
    end
    
    -- Find the highest priority taunt target
    for _, threat_data in ipairs(module.threat_table) do
        -- Skip targets already targeting a tank
        if threat_data.is_targeting_tank then
            goto continue
        end
        
        -- Check if priority meets threshold
        if threat_data.taunt_priority >= module.settings.taunt_threshold() then
            -- Check if spell is castable on this target
            if TankEngine.api.spell_helper:is_spell_queueable(spell_id, TankEngine.variables.me, threat_data.unit, skip_facing, skip_range) then
                return threat_data.unit
            end
        end
        
        ::continue::
    end
    
    return nil
end

---Get highest priority target for AoE threat generation
---@param spell_id number ID of the AoE threat spell to check castability
---@param range number Range of the AoE effect
---@param min_targets number Minimum number of targets required
---@param skip_facing boolean Whether to skip facing requirement
---@param skip_range boolean Whether to skip range requirement
---@return game_object|nil target The optimal target or nil
function TankEngine.modules.threat_manager.get_aoe_threat_target(spell_id, range, min_targets, skip_facing, skip_range)
    -- Validate parameters
    if not spell_id or not range or not min_targets then
        return nil
    end
    
    local best_target = nil
    local max_count = 0
    
    for _, enemy in ipairs(TankEngine.variables.nearby_enemies) do
        if enemy and enemy:is_valid() and not enemy:is_dead() and 
           TankEngine.api.spell_helper:is_spell_queueable(spell_id, TankEngine.variables.me, enemy, skip_facing, skip_range) then
            
            -- Count enemies within range of this target
            local count = 0
            for _, other in ipairs(TankEngine.variables.nearby_enemies) do
                if other and other:is_valid() and not other:is_dead() and 
                   enemy:get_position():dist_to(other:get_position()) <= range then
                    count = count + 1
                end
            end
            
            -- Update best target if we found more enemies
            if count >= min_targets and count > max_count then
                best_target = enemy
                max_count = count
            end
        end
    end
    
    return best_target
end

---Get highest priority target for general tanking (threat management)
---@param spell_id number ID of the threat spell to check castability
---@param skip_facing boolean Whether to skip facing requirement
---@param skip_range boolean Whether to skip range requirement
---@return game_object|nil target The optimal target or nil
function TankEngine.modules.threat_manager.get_threat_target(spell_id, skip_facing, skip_range)
    local module = TankEngine.modules.threat_manager
    
    -- Validate parameters
    if not spell_id then
        return nil
    end
    
    -- First check if we should taunt something
    local taunt_target = module.get_taunt_target(spell_id, skip_facing, skip_range)
    if taunt_target then
        return taunt_target
    end
    
    -- Otherwise find the highest threat value target that's castable
    local best_target = nil
    local best_value = 0
    
    for _, threat_data in ipairs(module.threat_table) do
        if threat_data.threat_value > best_value and 
           TankEngine.api.spell_helper:is_spell_queueable(spell_id, TankEngine.variables.me, threat_data.unit, skip_facing, skip_range) then
            best_target = threat_data.unit
            best_value = threat_data.threat_value
        end
    end
    
    return best_target
end

---Get target that needs to be interrupted
---@param spell_id number ID of the interrupt spell to check castability
---@param skip_facing boolean Whether to skip facing requirement
---@param skip_range boolean Whether to skip range requirement
---@param priority_only boolean Whether to only consider high-priority interrupts
---@return game_object|nil target The target to interrupt or nil
function TankEngine.modules.threat_manager.get_interrupt_target(spell_id, skip_facing, skip_range, priority_only)
    -- Validate parameters
    if not spell_id then
        return nil
    end
    
    for _, enemy in ipairs(TankEngine.variables.nearby_enemies) do
        if enemy and enemy:is_valid() and not enemy:is_dead() and enemy:is_casting_spell() then
            local spell = enemy:get_current_cast_spell()
            
            -- Skip if no spell info available
            if not spell then
                goto continue
            end
            
            -- Get spell ID and check if it's interruptible
            local enemy_spell_id = spell.spell_id
            if not enemy_spell_id or not TankEngine.api.spell_helper:is_spell_interruptible(enemy, enemy_spell_id) then
                goto continue
            end
            
            -- Check if this is a priority interrupt if priority_only is enabled
            if priority_only then
                -- TODO: Replace with actual priority interrupt check
                local is_priority = false
                
                -- Skip if not a priority interrupt
                if not is_priority then
                    goto continue
                end
            end
            
            -- Check if interrupt spell is castable on this target
            if TankEngine.api.spell_helper:is_spell_queueable(spell_id, TankEngine.variables.me, enemy, skip_facing, skip_range) then
                return enemy
            end
        end
        
        ::continue::
    end
    
    return nil
end

---Get a high health priority target for sustained threat
---@param spell_id number ID of the spell to check castability
---@param skip_facing boolean Whether to skip facing requirement
---@param skip_range boolean Whether to skip range requirement
---@return game_object|nil target The optimal target or nil
function TankEngine.modules.threat_manager.get_priority_threat_target(spell_id, skip_facing, skip_range)
    -- Validate parameters
    if not spell_id then
        return nil
    end
    
    local best_target = nil
    local best_score = 0
    
    for _, enemy in ipairs(TankEngine.variables.nearby_enemies) do
        if enemy and enemy:is_valid() and not enemy:is_dead() and 
           TankEngine.api.spell_helper:is_spell_queueable(spell_id, TankEngine.variables.me, enemy, skip_facing, skip_range) then
            
            -- Calculate priority score based on health, classification, and distance
            local health_pct = enemy:get_health() / enemy:get_max_health()
            local score = health_pct * 100  -- Higher health = higher score
            
            -- Bonus for elite/rare enemies
            local classification = enemy:get_classification()
            if classification == 1 then -- ELITE
                score = score * 1.3
            end
            
            if classification == 4 then -- RARE
                score = score * 1.2
            end
            
            if classification == 2 then -- RARE_ELITE
                score = score * 1.5
            end
            
            if classification == 3 then -- WORLD_BOSS
                score = score * 2.0
            end
            
            -- Adjust by distance (closer = higher score)
            local distance = TankEngine.variables.me:get_position():dist_to(enemy:get_position())
            score = score * (1 - (distance / 40) * 0.3)  -- Distance factor
            
            -- Adjust priority based on various factors
            
            -- Increase priority if this is our current target
            local current_target = nil
            if TankEngine.variables.target then
                if type(TankEngine.variables.target) == "function" then
                    current_target = TankEngine.variables.target()
                else
                    current_target = TankEngine.variables.target
                end
            end
            
            if current_target and enemy == current_target then
                score = score * 1.1  -- Small bonus for current target
            end
            
            if score > best_score then
                best_target = enemy
                best_score = score
            end
        end
    end
    
    return best_target
end
