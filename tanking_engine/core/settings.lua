---@type plugin_helper
local plugin_helper = require("common/utility/plugin_helper")

-- Settings manager for tanking engine
TankEngine.settings = {
    ---@type fun(): boolean
    is_enabled = function() return TankEngine.menu.enable_script_check:get_state() end,
    
    -- Humanizer settings
    humanizer = {
        ---@type fun(): boolean
        is_enabled = function() 
            if TankEngine.menu.humanizer and TankEngine.menu.humanizer.enable_humanizer then
                return TankEngine.menu.humanizer.enable_humanizer:get_state() 
            end
            return false
        end,
        
        ---@type fun(): integer
        min_delay = function() 
            if TankEngine.menu.humanizer and TankEngine.menu.humanizer.min_delay then
                return TankEngine.menu.humanizer.min_delay:get() 
            end
            return 125 -- Default value
        end,
        
        ---@type fun(): integer
        max_delay = function() 
            if TankEngine.menu.humanizer and TankEngine.menu.humanizer.max_delay then
                return TankEngine.menu.humanizer.max_delay:get() 
            end
            return 250 -- Default value
        end,
        
        -- Jitter settings
        jitter = {
            ---@type fun(): boolean
            is_enabled = function() 
                if TankEngine.menu.humanizer and TankEngine.menu.humanizer.jitter and TankEngine.menu.humanizer.jitter.enable_jitter then
                    return TankEngine.menu.humanizer.jitter.enable_jitter:get_state() 
                end
                return false
            end,
            
            ---@type fun(): number
            base_jitter = function() 
                if TankEngine.menu.humanizer and TankEngine.menu.humanizer.jitter and TankEngine.menu.humanizer.jitter.base_jitter then
                    return TankEngine.menu.humanizer.jitter.base_jitter:get() 
                end
                return 0.15 -- Default value
            end,
            
            ---@type fun(): number
            latency_jitter = function() 
                if TankEngine.menu.humanizer and TankEngine.menu.humanizer.jitter and TankEngine.menu.humanizer.jitter.latency_jitter then
                    return TankEngine.menu.humanizer.jitter.latency_jitter:get() 
                end
                return 0.05 -- Default value
            end,
            
            ---@type fun(): number
            max_jitter = function() 
                if TankEngine.menu.humanizer and TankEngine.menu.humanizer.jitter and TankEngine.menu.humanizer.jitter.max_jitter then
                    return TankEngine.menu.humanizer.jitter.max_jitter:get() 
                end
                return 0.25 -- Default value
            end,
        },
    },
    
    -- Threat management settings
    threat = {
        ---@type fun(): boolean
        prioritize_loose_mobs = function() return TankEngine.menu.threat.prioritize_loose_mobs:get_state() end,
        
        ---@type fun(): number
        taunt_threshold = function() return TankEngine.menu.threat.taunt_threshold:get() / 100 end,
        
        ---@type fun(): boolean
        auto_taunt = function() return TankEngine.menu.threat.auto_taunt:get_state() end,
        
        ---@type fun(): number
        target_swap_threshold = function() return TankEngine.menu.threat.target_swap_threshold:get() / 100 end,
    },
    
    -- Mitigation settings
    mitigation = {
        ---@type fun(): boolean
        consider_incoming_heals = function() return TankEngine.menu.mitigation.consider_incoming_heals:get_state() end,
        
        ---@type fun(): number
        heal_significance_threshold = function() return TankEngine.menu.mitigation.heal_significance_threshold:get() / 100 end,
        
        ---@type fun(): number
        major_cooldown_threshold = function() return TankEngine.menu.mitigation.major_cooldown_threshold:get() / 100 end,
        
        ---@type fun(): number
        minor_cooldown_threshold = function() return TankEngine.menu.mitigation.minor_cooldown_threshold:get() / 100 end,
        
        ---@type fun(): boolean
        predictive_mitigation = function() return TankEngine.menu.mitigation.predictive_mitigation:get_state() end,
        
        ---@type fun(): number
        active_mitigation_overlap = function() return TankEngine.menu.mitigation.active_mitigation_overlap:get() / 100 end,
        
        ---@type fun(): boolean
        save_for_spikes = function() return TankEngine.menu.mitigation.save_for_spikes:get_state() end,
    },
    
    -- Movement settings
    movement = {
        ---@type fun(): boolean
        auto_position = function() return TankEngine.menu.movement.auto_position:get_state() end,
        
        ---@type fun(): number
        kiting_threshold = function() return TankEngine.menu.movement.kiting_threshold:get() / 100 end,
        
        ---@type fun(): boolean
        maintain_range = function() return TankEngine.menu.movement.maintain_range:get_state() end,
    },
    
    -- Interrupt settings
    interrupt = {
        ---@type fun(): boolean
        auto_interrupt = function() return TankEngine.menu.interrupt.auto_interrupt:get_state() end,
        
        ---@type fun(): boolean
        prioritize_dangerous = function() return TankEngine.menu.interrupt.prioritize_dangerous:get_state() end,
        
        ---@type fun(): boolean
        save_for_important = function() return TankEngine.menu.interrupt.save_for_important:get_state() end,
    },
}

---Check if a toggle is enabled for UI keybinds
---@param keybind keybind
---@return boolean
function TankEngine.settings.is_toggle_enabled(keybind)
    return plugin_helper:is_toggle_enabled(keybind)
end
