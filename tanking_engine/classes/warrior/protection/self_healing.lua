-- Protection Warrior Self-Healing and Mitigation Prediction

-- Define relevant spell IDs
TankEngine.warrior_protection = TankEngine.warrior_protection or {}
TankEngine.warrior_protection.spells = {
    ignore_pain = 190456,
    shield_block = 2565,
    shield_slam = 23922,
    revenge = 6572,
    victory_rush = 34428,
    impending_victory = 202168, -- Talent replacing Victory Rush
    last_stand = 12975,
    rallying_cry = 97462,
    shield_wall = 871,
    spell_reflection = 23920,
    demoralizing_shout = 1160,
}

-- Predict potential self-healing and damage reduction for Protection Warrior
---@param timeframe_seconds number Time frame to consider for healing/mitigation prediction
---@return number mitigation_value Predicted effective health gain from healing and mitigation
function TankEngine.warrior_protection.predict_self_healing(timeframe_seconds)
    local me = TankEngine.variables.me
    local max_health = me:get_max_health()
    local current_rage = TankEngine.variables.resource(TankEngine.enums.power_type.RAGE)
    local potential_mitigation = 0
    
    -- Protection Warriors focus more on damage mitigation than direct healing
    -- Converting mitigation to equivalent healing for comparison purposes
    
    -- 1. Ignore Pain
    local ignore_pain_available = TankEngine.api.can_cast_spell(TankEngine.warrior_protection.spells.ignore_pain)
    local current_ip_absorb = 0
    
    -- Check if Ignore Pain is already active
    local ip_buff_id = 190456
    if TankEngine.variables.buff_up(ip_buff_id) then
        -- Rough estimation of remaining IP based on the buff stacks or value
        -- This is approximate as IP doesn't use standard stacks
        current_ip_absorb = max_health * 0.15 -- Estimation of current IP value
    end
    
    local max_ip_value = max_health * 0.30 -- Cap at 30% of max health
    
    if ignore_pain_available and current_rage >= 40 then
        local ip_power = 40 -- Base Rage cost
        local normalized_power = ip_power / 60 -- Normalize against maximum Rage (60)
        
        -- IP absorbs around 20% of max health at full Rage
        local new_ip_absorb = max_health * 0.20 * normalized_power
        
        -- Account for IP cap
        local potential_ip = math.min(current_ip_absorb + new_ip_absorb, max_ip_value)
        local actual_ip_gain = potential_ip - current_ip_absorb
        
        -- Add to potential mitigation
        potential_mitigation = potential_mitigation + actual_ip_gain
    end
    
    -- 2. Shield Block (physical damage reduction)
    local shield_block_available = TankEngine.api.can_cast_spell(TankEngine.warrior_protection.spells.shield_block)
    local shield_block_charges = core.spell_book.get_spell_charge(TankEngine.warrior_protection.spells.shield_block) or 0
    
    if shield_block_available and shield_block_charges > 0 and current_rage >= 30 then
        -- Shield Block reduces physical damage by 30%
        -- Convert to effective health for comparison (assumes 75% physical damage)
        local effective_health_gain = max_health * 0.30 * 0.75
        potential_mitigation = potential_mitigation + effective_health_gain
    end
    
    -- 3. Victory Rush / Impending Victory Healing
    local victory_rush_available = TankEngine.api.can_cast_spell(TankEngine.warrior_protection.spells.victory_rush) or
                                   TankEngine.api.can_cast_spell(TankEngine.warrior_protection.spells.impending_victory)
    
    if victory_rush_available then
        -- Victory Rush heals for 20% of max health
        potential_mitigation = potential_mitigation + (max_health * 0.20)
    end
    
    -- 4. Last Stand (emergency health increase)
    local last_stand_available = TankEngine.api.can_cast_spell(TankEngine.warrior_protection.spells.last_stand)
    local last_stand_cd = core.spell_book.get_spell_cooldown(TankEngine.warrior_protection.spells.last_stand)
    
    if last_stand_available and last_stand_cd == 0 then
        -- Last Stand increases max health by 30% for 15s
        -- This is equivalent to healing for 30% of max health
        potential_mitigation = potential_mitigation + (max_health * 0.30)
    end
    
    -- 5. Shield Wall (major defensive)
    local shield_wall_available = TankEngine.api.can_cast_spell(TankEngine.warrior_protection.spells.shield_wall)
    local shield_wall_cd = core.spell_book.get_spell_cooldown(TankEngine.warrior_protection.spells.shield_wall)
    
    if shield_wall_available and shield_wall_cd == 0 then
        -- Shield Wall reduces damage by 40%
        -- Convert to effective health (assuming equal magical/physical damage)
        local effective_health_gain = max_health * 0.40
        potential_mitigation = potential_mitigation + effective_health_gain
    end
    
    -- 6. Demoralizing Shout
    local demo_shout_available = TankEngine.api.can_cast_spell(TankEngine.warrior_protection.spells.demoralizing_shout)
    local demo_shout_cd = core.spell_book.get_spell_cooldown(TankEngine.warrior_protection.spells.demoralizing_shout)
    
    if demo_shout_available and demo_shout_cd == 0 then
        -- Demoralizing Shout reduces enemy damage by 20%
        -- Convert to effective health
        local effective_health_gain = max_health * 0.20
        potential_mitigation = potential_mitigation + effective_health_gain
    end
    
    -- Scaling based on timeframe (some abilities have cooldowns or resource costs)
    if timeframe_seconds < 3 then
        -- Reduce potential mitigation for shorter timeframes
        potential_mitigation = potential_mitigation * (timeframe_seconds / 3)
    end
    
    return potential_mitigation
end
