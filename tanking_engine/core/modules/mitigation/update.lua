---@class DamageEvent
---@field timestamp number Time when damage was taken
---@field amount number Amount of damage taken
---@field health_before number Health before damage
---@field health_after number Health after damage
---@field health_pct_before number Health percentage before damage
---@field health_pct_after number Health percentage after damage
---@field source game_object|nil Source of the damage

---Track a new damage event
---@param amount number
---@param source game_object|nil
local function record_damage_event(amount, source)
    local module = TankEngine.modules.mitigation
    local me = TankEngine.variables.me
    
    local current_health = me:get_health()
    local max_health = me:get_max_health()
    local health_pct = current_health / max_health
    
    local event = {
        timestamp = core.game_time(),
        amount = amount,
        health_before = current_health + amount,
        health_after = current_health,
        health_pct_before = (current_health + amount) / max_health,
        health_pct_after = health_pct,
        source = source
    }
    
    table.insert(module.damage_history, event)
    
    -- Update current health percentage
    module.current_health_pct = health_pct
    
    -- Cleanup old events
    local oldest_allowed = core.game_time() - module.damage_window
    while #module.damage_history > 0 and module.damage_history[1].timestamp < oldest_allowed do
        table.remove(module.damage_history, 1)
    end
end

---Calculate current damage taken per second
---@return number dtps
local function calculate_dtps()
    local module = TankEngine.modules.mitigation
    local total_damage = 0
    local window_start = core.game_time() - module.damage_window
    
    for _, event in ipairs(module.damage_history) do
        if event.timestamp >= window_start then
            total_damage = total_damage + event.amount
        end
    end
    
    return total_damage / (module.damage_window / 1000)
end

---Register and initialize a defensive ability
---@param spell_id number The spell ID
---@param name string The ability name
---@param is_major boolean Whether this is a major cooldown
---@param duration number Duration in milliseconds
---@param cooldown number Cooldown in milliseconds
---@param health_threshold number Health percentage threshold for auto-use
---@param priority number Priority for usage (higher = more important)
---@param requires_targeting boolean Whether this requires a target
---@param is_available function Function that returns true if available
function TankEngine.modules.mitigation.register_ability(spell_id, name, is_major, duration, cooldown, health_threshold, priority, requires_targeting, is_available)
    TankEngine.modules.mitigation.abilities[spell_id] = {
        spell_id = spell_id,
        name = name,
        is_major = is_major,
        duration = duration,
        cooldown = cooldown,
        health_threshold = health_threshold,
        last_used = 0,
        priority = priority,
        requires_targeting = requires_targeting,
        is_available = is_available or function() 
            return TankEngine.api.spell_helper:can_cast_spell(spell_id)
        end
    }
end

---Initialize default mitigation abilities
---This should be called by class-specific modules to register their abilities
function TankEngine.modules.mitigation.init_abilities()
    -- Initialize with class-agnostic abilities if any
    -- Class-specific modules will register their own abilities
end

---Perform fast updates for damage tracking
function TankEngine.modules.mitigation.on_fast_update()
    local current_time = core.game_time()
    
    -- Only update at specified intervals
    if current_time - TankEngine.modules.mitigation.last_update < TankEngine.modules.mitigation.update_interval then
        return
    end
    
    local me = TankEngine.variables.me
    if not me or not me:is_valid() or me:is_dead() then
        return
    end
    
    -- Get current health
    local current_health = me:get_health()
    local max_health = me:get_max_health()
    local current_health_pct = current_health / max_health
    
    -- Check if we took damage since last update
    if TankEngine.modules.mitigation.current_health_pct > current_health_pct then
        local health_diff = TankEngine.modules.mitigation.current_health_pct * max_health - current_health
        
        if health_diff > 0 then
            -- Record damage event
            record_damage_event(health_diff, nil) -- Source unknown in this context
        end
    end
    
    -- Calculate current DTPS
    TankEngine.modules.mitigation.current_dtps = calculate_dtps()
    
    -- Update damage prediction
    TankEngine.modules.mitigation.update_damage_prediction()
    
    -- Record last update
    TankEngine.modules.mitigation.last_update = current_time
end

---Process main update logic for the mitigation manager
function TankEngine.modules.mitigation.on_update()
    local me = TankEngine.variables.me
    if not me or not me:is_valid() or me:is_dead() or not me:is_in_combat() then
        return
    end
    
    -- Check active mitigation status
    local active_mitigation_up = TankEngine.variables.is_active_mitigation_up()
    local health_pct = TankEngine.modules.mitigation.current_health_pct
    
    -- Get incoming heals information if feature is enabled
    local effective_health_pct = health_pct
    if TankEngine.modules.mitigation.settings.consider_incoming_heals() then
        local _, health_with_heals_pct = TankEngine.modules.mitigation.calculate_effective_health(me)
        effective_health_pct = health_with_heals_pct
        
        -- If significant heals are incoming, log it
        if health_with_heals_pct > health_pct and 
           health_with_heals_pct - health_pct >= TankEngine.modules.mitigation.settings.heal_significance_threshold() then
            core.log(string.format("Incoming heals detected: %.1f%% health effect", 
                (health_with_heals_pct - health_pct) * 100))
        end
    end
    
    -- Determine if we need a defensive cooldown
    local need_minor_defensive = health_pct <= TankEngine.modules.mitigation.settings.minor_cooldown_threshold()
    local need_major_defensive = health_pct <= TankEngine.modules.mitigation.settings.major_cooldown_threshold()
    
    -- Check for predicted spike damage
    if TankEngine.modules.mitigation.settings.predictive_mitigation() then
        -- Adjust based on predicted damage
        if TankEngine.modules.mitigation.predicted_spike_incoming then
            need_minor_defensive = true
            
            -- If predicted loss would put us below major threshold, need major defensive
            local predicted_health_pct = health_pct - (TankEngine.modules.mitigation.predicted_health_loss / me:get_max_health())
            if predicted_health_pct <= TankEngine.modules.mitigation.settings.major_cooldown_threshold() then
                need_major_defensive = true
            end
        end
        
        -- Check for incoming boss abilities from BigWigs if available
        if TankEngine.modules.mitigation.check_incoming_boss_abilities then
            local dangerous_ability_coming, ability_info = TankEngine.modules.mitigation.check_incoming_boss_abilities()
            if dangerous_ability_coming and ability_info then
                -- Use appropriate defensive based on ability importance
                if ability_info.importance >= 9 then
                    -- Very high priority ability - use major defensive
                    need_major_defensive = true
                    core.log(string.format("Using major defensive for %s (Priority: %d)", 
                        ability_info.text, ability_info.importance))
                elseif ability_info.importance >= 7 then
                    -- High priority ability - use minor defensive at minimum
                    need_minor_defensive = true
                    core.log(string.format("Using defensive for %s (Priority: %d)", 
                        ability_info.text, ability_info.importance))
                end
            end
        end
    end
    
    -- Process defensives based on needs
    if need_major_defensive then
        -- Log the reason for using a major defensive
        local reason = "Health below threshold"
        if TankEngine.modules.mitigation.predicted_spike_incoming then
            reason = "Predicted damage spike"
        end
        
        -- Include information about self-healing if available
        local _, _, _, self_healing = TankEngine.modules.mitigation.calculate_effective_health(me)
        if self_healing > 0 then
            core.log(string.format("Using major defensive despite %.1f%% potential self-healing - %s", 
                (self_healing / max_health) * 100, reason))
        else
            core.log("Using major defensive: " .. reason)
        end
        
        TankEngine.modules.mitigation.use_best_defensive(true)
    elseif need_minor_defensive or 
          (active_mitigation_up and TankEngine.modules.mitigation.should_refresh_active_mitigation()) then
        TankEngine.modules.mitigation.use_best_defensive(false)
    end
end

---Check if we should refresh active mitigation
---@return boolean
function TankEngine.modules.mitigation.should_refresh_active_mitigation()
    -- Calculate remaining percentage of active mitigation
    local current_time = core.game_time()
    local expires = TankEngine.variables.mitigation_expires
    local remaining = math.max(0, expires - current_time)
    
    -- Get a representative active mitigation ability to check typical duration
    local typical_duration = 6000 -- Default 6 seconds if not found
    for _, ability in pairs(TankEngine.modules.mitigation.abilities) do
        if not ability.is_major then
            typical_duration = ability.duration
            break
        end
    end
    
    -- Calculate overlap threshold
    local overlap_threshold = typical_duration * TankEngine.modules.mitigation.settings.active_mitigation_overlap()
    
    -- Refresh if remaining time is less than threshold
    return remaining <= overlap_threshold
end

---Use the best available defensive ability
---@param major_only boolean Whether to only consider major cooldowns
---@return boolean success Whether a defensive was used
function TankEngine.modules.mitigation.use_best_defensive(major_only)
    local best_ability = nil
    local best_priority = 0
    
    for _, ability in pairs(TankEngine.modules.mitigation.abilities) do
        -- Skip if we're only looking for major cooldowns and this isn't one
        if major_only and not ability.is_major then
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
    
    -- Use the best ability found
    if best_ability then
        local target = best_ability.requires_targeting and TankEngine.variables.me:get_target() or nil
        
        if TankEngine.api.spell_helper:cast_spell(best_ability.spell_id, target) then
            -- Record usage
            best_ability.last_used = core.game_time()
            
            -- Set active mitigation status if this is a minor cooldown
            if not best_ability.is_major then
                TankEngine.variables.set_active_mitigation(best_ability.duration)
            end
            
            -- Log defensive usage
            core.log("Used defensive: " .. best_ability.name)
            
            return true
        end
    end
    
    return false
end

---Render mitigation visualizations
function TankEngine.modules.mitigation.on_render()
    -- Future implementation for visualization
end
