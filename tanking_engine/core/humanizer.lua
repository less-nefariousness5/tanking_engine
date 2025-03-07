-- Humanizer to add realistic delays between actions
TankEngine.humanizer = {
    next_run = 0,
}

---Applies jitter to a delay value
---@param delay number The base delay value
---@param latency number The current latency value
---@return number The delay with jitter applied
local function apply_jitter(delay, latency)
    -- Check if jitter settings exist and are enabled
    if not TankEngine.settings or not TankEngine.settings.humanizer or not TankEngine.settings.humanizer.jitter then
        core.log_error("Jitter settings not found in humanizer")
        return delay
    end
    
    if not TankEngine.settings.humanizer.jitter.is_enabled() then
        return delay
    end

    local latency_factor = math.min(latency / 200, 1) -- Normalize latency impact

    -- Calculate jitter percentage based on base jitter and latency
    local jitter_percent = TankEngine.settings.humanizer.jitter.base_jitter() +
        (TankEngine.settings.humanizer.jitter.latency_jitter() * latency_factor)

    -- Clamp total jitter to max_jitter
    jitter_percent = math.min(jitter_percent, TankEngine.settings.humanizer.jitter.max_jitter())

    -- Calculate jitter range
    local jitter_range = delay * jitter_percent

    -- Apply random jitter within range
    return delay + (math.random() * 2 - 1) * jitter_range
end

---Check if the engine can run based on humanized timing
---@return boolean
function TankEngine.humanizer.can_run()
    return core.game_time() >= TankEngine.humanizer.next_run
end

---Update the next run time with humanized delay
function TankEngine.humanizer.update()
    -- Check if humanizer settings exist
    if not TankEngine.settings or not TankEngine.settings.humanizer then
        core.log_error("Humanizer settings not found")
        TankEngine.humanizer.next_run = core.game_time()
        return
    end
    
    -- Only apply humanization if enabled
    if not TankEngine.settings.humanizer.is_enabled() then
        TankEngine.humanizer.next_run = core.game_time()
        return
    end

    local latency = core.get_ping() * 1.5
    
    -- Check if min_delay and max_delay functions exist
    if not TankEngine.settings.humanizer.min_delay or not TankEngine.settings.humanizer.max_delay then
        core.log_error("Humanizer min_delay or max_delay function is nil")
        TankEngine.humanizer.next_run = core.game_time() + 100 -- Default delay of 100ms
        return
    end
    
    local min_delay = TankEngine.settings.humanizer.min_delay() + latency
    local max_delay = TankEngine.settings.humanizer.max_delay() + latency

    -- Get base delay
    local base_delay = math.random(min_delay, max_delay)

    -- Apply jitter to the delay
    local final_delay = apply_jitter(base_delay, latency)

    TankEngine.humanizer.next_run = final_delay + core.game_time()
end

-- Extra combat-specific humanization functions

---Adds realistic reaction delay for defensive responses
---@param threat_level number The threat level (0-1)
---@return number Reaction delay in milliseconds
function TankEngine.humanizer.defensive_reaction_delay(threat_level)
    -- More threatening situations get faster reactions
    local base_reaction = math.max(100, 500 * (1 - threat_level))
    return apply_jitter(base_reaction, core.get_ping())
end

---Adds realistic target switching delay
---@param distance number Distance to the new target
---@return number Target switch delay in milliseconds
function TankEngine.humanizer.target_switch_delay(distance)
    -- Farther targets take longer to switch to
    local base_delay = math.min(300, 50 + (distance * 10))
    return apply_jitter(base_delay, core.get_ping())
end
