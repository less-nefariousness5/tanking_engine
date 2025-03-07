-- Vengeance Demon Hunter Self-Healing Prediction

-- Define relevant spell IDs
TankEngine.vengeance = TankEngine.vengeance or {}
TankEngine.vengeance.spells = {
    soul_cleave = 228477,
    spirit_bomb = 247454,
    fiery_brand = 204021,
    fel_devastation = 212084,
    soul_barrier = 263648,
    metamorphosis = 187827,
    shear = 203782,
    fracture = 263642, -- Talent replacing Shear
    soul_fragment_consume = 178740, -- Consume Soul (healing from soul fragments)
    demon_spikes = 203720,
}

TankEngine.vengeance.soul_fragment_healing_percent = 0.08 -- 8% of max health per fragment

-- Count active soul fragments
---@return number count Number of active soul fragments
function TankEngine.vengeance.count_soul_fragments()
    local me = TankEngine.variables.me
    
    -- Soul fragments are tracked by an aura with stacks
    -- Assuming the aura ID for tracking is 203981 for Soul Fragments
    local fragment_aura_id = 203981
    local fragments = TankEngine.variables.buff_stacks(fragment_aura_id) or 0
    
    return fragments
end

-- Predict potential self-healing for Vengeance Demon Hunter
---@param timeframe_seconds number Time frame to consider for healing prediction
---@return number healing_amount Predicted healing amount
function TankEngine.vengeance.predict_self_healing(timeframe_seconds)
    local me = TankEngine.variables.me
    local max_health = me:get_max_health()
    local current_fury = TankEngine.variables.resource(TankEngine.enums.power_type.FURY)
    local potential_healing = 0
    
    -- 1. Soul Fragment Healing
    local soul_fragments = TankEngine.vengeance.count_soul_fragments()
    local fragment_healing = soul_fragments * (max_health * TankEngine.vengeance.soul_fragment_healing_percent)
    
    -- 2. Soul Cleave Potential
    local soul_cleave_available = TankEngine.api.can_cast_spell(TankEngine.vengeance.spells.soul_cleave)
    if soul_cleave_available and current_fury >= 30 then
        -- Soul Cleave consumes up to 2 fragments and heals for each
        local consumable_fragments = math.min(2, soul_fragments)
        local cleave_healing = consumable_fragments * (max_health * TankEngine.vengeance.soul_fragment_healing_percent)
        -- Soul Cleave also has base healing of ~5% max health
        cleave_healing = cleave_healing + (max_health * 0.05)
        potential_healing = potential_healing + cleave_healing
    end
    
    -- 3. Spirit Bomb Potential
    local spirit_bomb_available = TankEngine.api.can_cast_spell(TankEngine.vengeance.spells.spirit_bomb)
    if spirit_bomb_available and current_fury >= 30 and soul_fragments >= 4 then
        -- Spirit Bomb consumes all fragments and applies DoT healing to nearby enemies
        -- This healing is hard to estimate, but it's approximately 10% of max health for 5 fragments
        potential_healing = potential_healing + (max_health * 0.10)
    end
    
    -- 4. Fel Devastation
    local fel_dev_available = TankEngine.api.can_cast_spell(TankEngine.vengeance.spells.fel_devastation)
    local fel_dev_cd = core.spell_book.get_spell_cooldown(TankEngine.vengeance.spells.fel_devastation)
    if fel_dev_available and fel_dev_cd == 0 and current_fury >= 50 and timeframe_seconds >= 2 then
        -- Fel Devastation heals for ~3% max health per second, for 2 seconds
        potential_healing = potential_healing + (max_health * 0.06)
    end
    
    -- 5. Soul Barrier
    local soul_barrier_available = TankEngine.api.can_cast_spell(TankEngine.vengeance.spells.soul_barrier)
    local soul_barrier_cd = core.spell_book.get_spell_cooldown(TankEngine.vengeance.spells.soul_barrier)
    if soul_barrier_available and soul_barrier_cd == 0 and timeframe_seconds >= 1 then
        -- Soul Barrier absorbs damage rather than healing, but functionally similar
        -- Base shield of ~30% max health, plus 12% per Soul Fragment consumed
        local shield_amount = max_health * 0.30 + (soul_fragments * max_health * 0.12)
        potential_healing = potential_healing + shield_amount
    end
    
    -- 6. Metamorphosis (emergency cooldown)
    local meta_available = TankEngine.api.can_cast_spell(TankEngine.vengeance.spells.metamorphosis)
    local meta_cd = core.spell_book.get_spell_cooldown(TankEngine.vengeance.spells.metamorphosis)
    if meta_available and meta_cd == 0 and timeframe_seconds >= 1 then
        -- Metamorphosis gives immediate health (30% of max health)
        potential_healing = potential_healing + (max_health * 0.30)
    end
    
    -- Scaling based on timeframe (some abilities have cooldowns or resource costs)
    if timeframe_seconds < 3 then
        -- Reduce potential healing for shorter timeframes
        potential_healing = potential_healing * (timeframe_seconds / 3)
    end
    
    return potential_healing
end
