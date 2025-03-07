-- Protection Paladin Self-Healing Prediction

-- Define relevant spell IDs
TankEngine.paladin_protection = TankEngine.paladin_protection or {}
TankEngine.paladin_protection.spells = {
    word_of_glory = 85673,
    lay_on_hands = 633,
    shield_of_the_righteous = 53600,
    divine_shield = 642,
    ardent_defender = 31850,
    guardian_of_ancient_kings = 86659,
    divine_purpose = 223817, -- Buff that makes next WoG free
    consecration = 26573,
    avengers_shield = 31935,
    judgment = 275779,
    blessed_hammer = 204019,
    holy_power_builder = 204019, -- Any HP builder (using Blessed Hammer as default)
}

-- Predict potential self-healing for Protection Paladin
---@param timeframe_seconds number Time frame to consider for healing prediction
---@return number healing_amount Predicted healing amount
function TankEngine.paladin_protection.predict_self_healing(timeframe_seconds)
    local me = TankEngine.variables.me
    local max_health = me:get_max_health()
    local current_health = me:get_health()
    local health_pct = current_health / max_health
    local current_holy_power = TankEngine.variables.resource(TankEngine.enums.power_type.HOLYPOWER)
    local potential_healing = 0
    
    -- 1. Word of Glory / Shield of the Righteous decision logic
    local word_of_glory_available = TankEngine.api.can_cast_spell(TankEngine.paladin_protection.spells.word_of_glory)
    
    -- Check for Divine Purpose proc
    local divine_purpose_active = TankEngine.variables.buff_up(TankEngine.paladin_protection.spells.divine_purpose)
    
    -- Estimate how much Holy Power we can generate in the timeframe
    local potential_holy_power = current_holy_power
    
    -- Estimate Holy Power generation
    if timeframe_seconds >= 1.5 then -- Typical GCD for builders
        -- Blessed Hammer / Judgment / Avenger's Shield each generate 1 Holy Power
        local builders_per_second = 0.6 -- Approximate rate of Holy Power generation per second
        potential_holy_power = potential_holy_power + math.floor(timeframe_seconds * builders_per_second)
    end
    
    -- Cap at 5 Holy Power
    potential_holy_power = math.min(5, potential_holy_power)
    
    -- Word of Glory healing calculation
    if word_of_glory_available and (potential_holy_power >= 3 or divine_purpose_active) then
        -- Word of Glory base healing (approximately 130% of SP plus 30% of AP)
        -- For simplicity, using a percentage of max health
        local wog_healing_pct = 0.35 -- Base healing is around 35% of max health
        
        -- Scaling with Holy Power
        if not divine_purpose_active then
            wog_healing_pct = wog_healing_pct * (potential_holy_power / 3)
        end
        
        -- Protection paladins have increased WoG healing when below 60% health
        if health_pct < 0.6 then
            wog_healing_pct = wog_healing_pct * 1.3 -- 30% increase
        end
        
        potential_healing = potential_healing + (max_health * wog_healing_pct)
    end
    
    -- 2. Lay on Hands (emergency healing)
    local lay_on_hands_available = TankEngine.api.can_cast_spell(TankEngine.paladin_protection.spells.lay_on_hands)
    local lay_on_hands_cd = core.spell_book.get_spell_cooldown(TankEngine.paladin_protection.spells.lay_on_hands)
    
    if lay_on_hands_available and lay_on_hands_cd == 0 then
        -- Lay on Hands heals for 100% of max health
        potential_healing = potential_healing + max_health
    end
    
    -- 3. Shield of the Righteous (damage reduction, not healing)
    local sotr_available = TankEngine.api.can_cast_spell(TankEngine.paladin_protection.spells.shield_of_the_righteous)
    
    if sotr_available and potential_holy_power >= 3 and not divine_purpose_active then
        -- SotR reduces physical damage by ~40%
        -- Convert to effective health for 8 seconds (typical duration)
        -- Assume 70% physical damage
        local effective_damage_reduction = max_health * 0.4 * 0.7
        
        -- Only count this if we're above 60% health (prioritize WoG when lower)
        if health_pct > 0.6 then
            potential_healing = potential_healing + effective_damage_reduction
        end
    end
    
    -- 4. Ardent Defender
    local ardent_defender_available = TankEngine.api.can_cast_spell(TankEngine.paladin_protection.spells.ardent_defender)
    local ardent_defender_cd = core.spell_book.get_spell_cooldown(TankEngine.paladin_protection.spells.ardent_defender)
    
    if ardent_defender_available and ardent_defender_cd == 0 then
        -- Ardent Defender reduces damage by 20% and prevents death
        -- Convert to effective health
        local effective_health_gain = max_health * 0.2
        
        -- Add potential death prevention value (20% of max health)
        if health_pct < 0.4 then
            effective_health_gain = effective_health_gain + (max_health * 0.2)
        end
        
        potential_healing = potential_healing + effective_health_gain
    end
    
    -- 5. Guardian of Ancient Kings
    local goak_available = TankEngine.api.can_cast_spell(TankEngine.paladin_protection.spells.guardian_of_ancient_kings)
    local goak_cd = core.spell_book.get_spell_cooldown(TankEngine.paladin_protection.spells.guardian_of_ancient_kings)
    
    if goak_available and goak_cd == 0 then
        -- Guardian of Ancient Kings reduces damage by 50%
        -- Convert to effective health
        local effective_health_gain = max_health * 0.5
        potential_healing = potential_healing + effective_health_gain
    end
    
    -- 6. Divine Shield (for extreme emergencies)
    local divine_shield_available = TankEngine.api.can_cast_spell(TankEngine.paladin_protection.spells.divine_shield)
    local divine_shield_cd = core.spell_book.get_spell_cooldown(TankEngine.paladin_protection.spells.divine_shield)
    
    if divine_shield_available and divine_shield_cd == 0 and health_pct < 0.2 then
        -- Divine Shield provides immunity, effectively giving 100% damage reduction
        -- Convert to effective health (limited duration and drops threat)
        local effective_health_gain = max_health * 0.8
        potential_healing = potential_healing + effective_health_gain
    end
    
    -- Scaling based on timeframe (some abilities have cooldowns or resource costs)
    if timeframe_seconds < 3 then
        -- Reduce potential healing for shorter timeframes
        potential_healing = potential_healing * (timeframe_seconds / 3)
    end
    
    return potential_healing
end
