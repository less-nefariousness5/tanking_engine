---@class EnemyData
---@field unit game_object The enemy unit
---@field cast_history table<number, number> Map of spell ID to last cast time
---@field cooldowns table<number, number> Map of ability ID to cooldown end time
---@field interrupt_priority number Priority for interruption (higher = more important)
---@field is_dangerous boolean Whether this enemy is considered dangerous
---@field current_cast table|nil Current cast information if casting
---@field pathing_pattern string|nil Detected movement pattern
---@field position_history table Array of recent positions

-- Initialize enemy tracking module
TankEngine.modules.enemy_tracking = {
    ---@type table<game_object, EnemyData>
    tracked_enemies = {},
    
    -- Spell database for known dangerous casts
    ---@type table<number, boolean>
    dangerous_spells = {},
    
    -- Interrupt priority database
    ---@type table<number, number>
    interrupt_priorities = {},
    
    -- Last update time
    last_update = 0,
    
    -- Update interval (ms)
    update_interval = 100,
    
    -- Module settings
    settings = {
        -- Convert static values to functions that retrieve values from menu elements
        max_tracking_distance = function() return TankEngine.modules.enemy_tracking.menu.max_tracking_distance:get() end,
        position_history_length = function() return TankEngine.modules.enemy_tracking.menu.position_history_length:get() end,
        enable_pathing_prediction = function() return TankEngine.modules.enemy_tracking.menu.enable_pathing_prediction:get_state() end,
    },
    
    -- Menu configuration
    menu = {
        tree = TankEngine.menu.tree_node(),
        -- Define menu elements with proper tag
        max_tracking_distance = core.menu.slider_int(30, 100, 60, "enemy_tracking_max_tracking_distance"),
        position_history_length = core.menu.slider_int(5, 20, 10, "enemy_tracking_position_history_length"),
        enable_pathing_prediction = core.menu.checkbox(true, "enemy_tracking_enable_pathing_prediction")
    }
}

-- Load module files
require("core/modules/enemy_tracking/menu")
require("core/modules/enemy_tracking/update")
require("core/modules/enemy_tracking/spell_tracking")
require("core/modules/enemy_tracking/pathing_prediction")

-- Export module interface
---@type ModuleConfig
return {
    on_update = TankEngine.modules.enemy_tracking.on_update,
    on_fast_update = TankEngine.modules.enemy_tracking.on_fast_update,
    on_render_menu = TankEngine.modules.enemy_tracking.menu.on_render_menu,
    on_render = TankEngine.modules.enemy_tracking.on_render
}
