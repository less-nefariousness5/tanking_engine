---@class ThreatData
---@field unit game_object The enemy unit
---@field target game_object|nil The unit's current target
---@field threat_value number Estimated threat value (0-100)
---@field taunt_priority number Priority for taunting (higher = more important)
---@field last_target_change number Game time of last target change
---@field is_targeting_tank boolean Whether unit is targeting the tank
---@field is_targeting_healer boolean Whether unit is targeting a healer
---@field is_targeting_dps boolean Whether unit is targeting a DPS
---@field distance number Distance to the tank

-- Initialize threat manager module
TankEngine.modules.threat_manager = {
    ---@type ThreatData[]
    threat_table = {},
    
    -- Last update time
    last_update = 0,
    
    -- Threat update interval (ms)
    update_interval = 250,
    
    -- Taunt history for each enemy
    taunt_history = {},
    
    -- Group members categorized
    tanks = {},
    healers = {},
    dps = {},
    
    -- Module settings
    settings = {
        ---@type fun(): boolean
        prioritize_loose_mobs = function() return TankEngine.settings.threat.prioritize_loose_mobs() end,
        
        ---@type fun(): number
        taunt_threshold = function() return TankEngine.settings.threat.taunt_threshold() end,
        
        ---@type fun(): boolean
        auto_taunt = function() return TankEngine.settings.threat.auto_taunt() end,
        
        ---@type fun(): number
        target_swap_threshold = function() return TankEngine.settings.threat.target_swap_threshold() end,
    },
    
    -- Menu configuration
    menu = {
        tree = TankEngine.menu.tree_node(),
    }
}

-- Load module files
require("core/modules/threat_manager/menu")
require("core/modules/threat_manager/update")
require("core/modules/threat_manager/target_selection")
require("core/modules/threat_manager/threat_calculation")

-- Export module interface
---@type ModuleConfig
return {
    on_update = TankEngine.modules.threat_manager.on_update,
    on_fast_update = TankEngine.modules.threat_manager.on_fast_update,
    on_render_menu = TankEngine.modules.threat_manager.menu.on_render_menu,
    on_render = TankEngine.modules.threat_manager.on_render
}
