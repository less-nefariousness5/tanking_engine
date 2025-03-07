---@class MitigationData
---@field spell_id number The defensive spell ID
---@field name string The name of the defensive ability
---@field is_major boolean Whether this is a major cooldown
---@field duration number Duration in milliseconds
---@field cooldown number Cooldown in milliseconds
---@field health_threshold number Health percentage threshold for automatic use
---@field last_used number Last time this ability was used
---@field priority number Priority for usage (higher = more important)
---@field requires_targeting boolean Whether this ability requires a target
---@field is_available function Function that returns true if the ability is available

-- Initialize mitigation manager module
TankEngine.modules.mitigation = {
    ---@type table<number, MitigationData>
    abilities = {},
    
    -- Track damage intake
    damage_history = {},
    
    -- Damage tracking window (ms)
    damage_window = 5000,
    
    -- Last update time
    last_update = 0,
    
    -- Update interval (ms)
    update_interval = 100,
    
    -- Current smoothed damage intake
    current_dtps = 0, -- Damage Taken Per Second
    
    -- Current health percentage
    current_health_pct = 1.0,
    
    -- Defensive prediction
    predicted_health_loss = 0,
    predicted_spike_incoming = false,
    
    -- Module settings
    settings = {
        ---@type fun(): boolean
        consider_incoming_heals = function() return TankEngine.settings.mitigation.consider_incoming_heals() end,
        
        ---@type fun(): number
        heal_significance_threshold = function() return TankEngine.settings.mitigation.heal_significance_threshold() end,
        ---@type fun(): number
        major_cooldown_threshold = function() return TankEngine.settings.mitigation.major_cooldown_threshold() end,
        
        ---@type fun(): number
        minor_cooldown_threshold = function() return TankEngine.settings.mitigation.minor_cooldown_threshold() end,
        
        ---@type fun(): boolean
        predictive_mitigation = function() return TankEngine.settings.mitigation.predictive_mitigation() end,
        
        ---@type fun(): number
        active_mitigation_overlap = function() return TankEngine.settings.mitigation.active_mitigation_overlap() end,
        
        ---@type fun(): boolean
        save_for_spikes = function() return TankEngine.settings.mitigation.save_for_spikes() end,
    },
    
    -- Menu configuration
    menu = {
        tree = TankEngine.menu.tree_node(),
    }
}

-- Load module files
require("core/modules/mitigation/menu")
require("core/modules/mitigation/update")
require("core/modules/mitigation/ability_selection")
require("core/modules/mitigation/damage_prediction")
require("core/modules/mitigation/heal_awareness")

-- Export module interface
---@type ModuleConfig
return {
    on_update = TankEngine.modules.mitigation.on_update,
    on_fast_update = TankEngine.modules.mitigation.on_fast_update,
    on_render_menu = TankEngine.modules.mitigation.menu.on_render_menu,
    on_render = TankEngine.modules.mitigation.on_render
}
