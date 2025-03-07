-- Heal awareness system to prevent wasting defensive cooldowns when heals are incoming

--- Calculate effective health including incoming heals and potential self-healing
---@param unit game_object The unit to check (usually the player)
---@return number effective_health The unit's health plus incoming heals and potential self-healing
---@return number health_with_heals_percent The percentage of effective health (health + heals + self-healing)
---@return number external_healing Amount of external healing incoming
---@return number self_healing Amount of potential self-healing available
function TankEngine.modules.mitigation.calculate_effective_health(unit)
    if not unit or not unit:is_valid() or unit:is_dead() then
        return 0, 0, 0, 0
    end
    
    -- Get base health values
    local current_health = unit:get_health()
    local max_health = unit:get_max_health()
    local health_percent = current_health / max_health
    
    -- Get incoming heals
    local incoming_heals = unit:get_incoming_heals()
    
    -- Get potential self-healing
    local self_healing = 0
    if unit == TankEngine.variables.me then
        -- Get class-specific self-healing prediction
        local player_class = unit:get_class()
        local player_spec_id = core.spell_book.get_specialization_id()
        
        -- Check for specific tank specs
        if player_class == 12 and player_spec_id == 2 then -- Vengeance DH
            if TankEngine.vengeance and TankEngine.vengeance.predict_self_healing then
                self_healing = TankEngine.vengeance.predict_self_healing(3) -- Look ahead 3 seconds
            end
        elseif player_class == 1 and player_spec_id == 3 then -- Protection Warrior
            if TankEngine.warrior_protection and TankEngine.warrior_protection.predict_self_healing then
                self_healing = TankEngine.warrior_protection.predict_self_healing(3)
            end
        elseif player_class == 2 and player_spec_id == 1 then -- Protection Paladin
            if TankEngine.paladin_protection and TankEngine.paladin_protection.predict_self_healing then
                self_healing = TankEngine.paladin_protection.predict_self_healing(3)
            end
        end
    end
    
    -- Calculate effective health and percentage
    local effective_health = current_health + incoming_heals + self_healing
    local health_with_heals_percent = math.min(1.0, effective_health / max_health) -- Cap at 100%
    
    return effective_health, health_with_heals_percent, incoming_heals, self_healing
end

--- Check if incoming heals are sufficient to prevent defensive cooldown usage
---@param health_threshold number Health threshold for cooldown usage
---@param significance_threshold number Heal significance threshold (0.0-1.0)
---@return boolean should_wait Whether to wait for heals instead of using a cooldown
---@return number heal_impact How significant the incoming heals are (0.0-1.0)
---@return number self_healing_impact How significant self-healing is (0.0-1.0)
function TankEngine.modules.mitigation.should_wait_for_heals(health_threshold, significance_threshold)
    local me = TankEngine.variables.me
    local current_health = me:get_health()
    local max_health = me:get_max_health()
    local current_health_pct = current_health / max_health
    
    -- If health is critically low, don't wait regardless of incoming heals
    local critical_threshold = health_threshold * 0.6
    if current_health_pct < critical_threshold then
        return false, 0, 0
    end
    
    -- Get incoming heals and calculate effective health
    local effective_health, effective_health_pct, incoming_heals, self_healing = 
        TankEngine.modules.mitigation.calculate_effective_health(me)
    
    -- Calculate the impact of external healing and self-healing separately
    local external_heal_pct = incoming_heals / max_health
    local self_heal_pct = self_healing / max_health
    
    -- Total healing impact
    local heal_impact = (effective_health_pct - current_health_pct)
    
    -- Different logic based on healing sources
    local has_significant_external = external_heal_pct >= significance_threshold
    local has_significant_self = self_heal_pct >= significance_threshold
    
    -- Different threshold adjustments based on healing type
    local adjusted_threshold = health_threshold
    
    -- Self-healing is more reliable, so we're more confident delaying for it
    if has_significant_self then
        adjusted_threshold = health_threshold * 0.95
    end
    
    -- Check if the heals will bring us above the adjusted threshold
    if effective_health_pct > adjusted_threshold and heal_impact >= significance_threshold then
        return true, heal_impact, self_heal_pct
    end
    
    return false, heal_impact, self_heal_pct
end

--- Get information about incoming heals from party members
---@return table heal_sources Table with information about heal sources
function TankEngine.modules.mitigation.get_heal_sources()
    local me = TankEngine.variables.me
    local healers = {}
    local heal_sources = {}
    
    -- Find all healers in the party
    for _, unit in ipairs(TankEngine.modules.threat_manager.healers) do
        if unit and unit:is_valid() and not unit:is_dead() then
            table.insert(healers, unit)
        end
    end
    
    -- Get incoming heals from each healer
    for _, healer in ipairs(healers) do
        -- Note: get_incoming_heals_from should work here if the API properly supports it
        -- For now, we'll use a simplified approach since the exact API usage isn't clear
        local healer_name = healer:get_name()
        
        -- Add to heal sources table
        table.insert(heal_sources, {
            unit = healer,
            name = healer_name,
            is_casting = healer:is_casting_spell(),
            spell_id = healer:is_casting_spell() and healer:get_active_spell_id() or 0,
            target = healer:is_casting_spell() and healer:get_active_spell_target() or nil
        })
    end
    
    return heal_sources
end

--- Check if a healer is actively casting a healing spell on the player
---@return boolean is_being_healed Whether player is actively being healed
---@return number expected_heal_amount Estimated amount of incoming heal
function TankEngine.modules.mitigation.is_being_actively_healed()
    local me = TankEngine.variables.me
    local heal_sources = TankEngine.modules.mitigation.get_heal_sources()
    local is_being_healed = false
    local expected_heal_amount = 0
    
    for _, source in ipairs(heal_sources) do
        if source.is_casting and source.target and source.target == me then
            is_being_healed = true
            -- In a real implementation, we might estimate heal amount based on spell_id
            -- For now, we'll use a simplified approach
            expected_heal_amount = expected_heal_amount + (me:get_max_health() * 0.2) -- Rough estimate
        end
    end
    
    return is_being_healed, expected_heal_amount
end

--- Enhanced defensive cooldown decision making with heal awareness
---@param spell_id number The defensive spell ID to consider using
---@param health_threshold number Health threshold for using this cooldown
---@param is_major boolean Whether this is a major cooldown
---@return boolean should_use Whether to use the defensive cooldown
function TankEngine.modules.mitigation.should_use_defensive_with_heal_awareness(spell_id, health_threshold, is_major)
    local me = TankEngine.variables.me
    local current_health_pct = me:get_health() / me:get_max_health()
    
    -- If health is above threshold, no need for a defensive
    if current_health_pct > health_threshold then
        return false
    end
    
    -- Check predicted damage to see if we need immediate defense
    local predicted_damage, is_spike = TankEngine.modules.mitigation.get_damage_prediction()
    local health_after_damage = current_health_pct - predicted_damage
    
    -- If incoming damage would be fatal or critical, use defensive regardless of heals
    if health_after_damage < 0.15 then
        return true
    end
    
    -- If this is a major cooldown, we should be more conservative
    local heal_significance_threshold = is_major and 0.1 or 0.05
    
    -- Check if we should wait for incoming heals and/or self-healing
    local should_wait, heal_impact, self_heal_impact = TankEngine.modules.mitigation.should_wait_for_heals(
        health_threshold, 
        heal_significance_threshold
    )
    
    -- If spike damage predicted and this is a major cooldown, prioritize defense
    if is_spike and is_major then
        -- Even with heals incoming, if damage is spiking use major defensive
        return true
    end
    
    -- Check if someone is actively healing us
    local being_healed, _ = TankEngine.modules.mitigation.is_being_actively_healed()
    
    -- Special handling for significant self-healing potential
    if self_heal_impact >= heal_significance_threshold * 1.5 then
        -- If we have strong self-healing available and it's not a dire situation
        if not is_spike and health_after_damage > 0.3 then
            -- Log that we're relying on self-healing rather than using a cooldown
            core.log(string.format("Delaying defensive cooldown - self-healing will restore %.1f%% health", 
                self_heal_impact * 100))
            return false
        end
    end
    
    -- If we're being actively healed and there's significant heal impact, wait for the heal
    if (being_healed or self_heal_impact > 0) and should_wait then
        -- Log that we're delaying cooldown use due to incoming heals
        core.log(string.format("Delaying defensive cooldown - healing will restore %.1f%% health", 
            heal_impact * 100))
        return false
    end
    
    -- Default to normal defensive logic
    return current_health_pct <= health_threshold
end
