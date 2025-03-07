---@type color 
local color = require("common/color")

-- Initialize positioning module
TankEngine.modules.positioning = {
    -- Current recommended position
    recommended_position = nil,
    
    -- Current kiting path
    kiting_path = {},
    
    -- Whether currently kiting
    is_kiting = false,
    
    -- Position history of the player
    player_position_history = {},
    
    -- Last update time
    last_update = 0,
    
    -- Update interval (ms)
    update_interval = 250,
    
    -- Module settings
    settings = {
        ---@type fun(): boolean
        auto_position = function() return TankEngine.settings.movement.auto_position() end,
        
        ---@type fun(): number
        kiting_threshold = function() return TankEngine.settings.movement.kiting_threshold() end,
        
        ---@type fun(): boolean
        maintain_range = function() return TankEngine.settings.movement.maintain_range() end,
        
        -- Positioning parameters
        preferred_range = function() return TankEngine.modules.positioning.menu.preferred_range:get() end,
        max_range = function() return TankEngine.modules.positioning.menu.max_range:get() end,
        kiting_distance = function() return TankEngine.modules.positioning.menu.kiting_distance:get() end,
        safe_zone_radius = function() return TankEngine.modules.positioning.menu.safe_zone_radius:get() end,
        show_positioning = function() return TankEngine.modules.positioning.menu.show_positioning:get_state() end,
        show_kiting_path = function() return TankEngine.modules.positioning.menu.show_kiting_path:get_state() end,
        position_history_length = 10, -- Number of positions to remember
    },
    
    -- Menu configuration
    menu = {
        tree = TankEngine.menu.tree_node(),
        -- Define menu elements with proper tag
        preferred_range = core.menu.slider_float(3, 15, 5, "positioning_preferred_range"),
        max_range = core.menu.slider_float(10, 50, 30, "positioning_max_range"),
        kiting_distance = core.menu.slider_float(5, 30, 15, "positioning_kiting_distance"),
        safe_zone_radius = core.menu.slider_float(3, 10, 5, "positioning_safe_zone_radius"),
        show_positioning = core.menu.checkbox(true, "positioning_show_positioning"),
        show_kiting_path = core.menu.checkbox(true, "positioning_show_kiting_path"),
        position_color = core.menu.colorpicker(color.new(0, 255, 0, 128), "positioning_position_color")
    }
}

-- Load module files
require("core/modules/positioning/menu")
require("core/modules/positioning/update")
require("core/modules/positioning/position_selection")
require("core/modules/positioning/kiting")

-- Export module interface
---@type ModuleConfig
return {
    on_update = TankEngine.modules.positioning.on_update,
    on_fast_update = TankEngine.modules.positioning.on_fast_update,
    on_render_menu = TankEngine.modules.positioning.menu.on_render_menu,
    on_render = TankEngine.modules.positioning.on_render
}
