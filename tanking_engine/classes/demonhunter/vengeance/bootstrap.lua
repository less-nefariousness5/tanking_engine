-- Vengeance Demon Hunter specialization bootstrap

-- Initialize namespace
TankEngine.vengeance = TankEngine.vengeance or {}

-- Load modules
require("classes/demonhunter/vengeance/self_healing")

-- Define enums for resources
TankEngine.enums = TankEngine.enums or {}
TankEngine.enums.power_type = {
    FURY = 17,
    PAIN = 18,
    RAGE = 1,
    HOLYPOWER = 9,
}

-- Return spec configuration
---@type SpecConfig
return {
    spec_id = 2, -- Vengeance spec ID
    class_id = 12, -- Demon Hunter class ID
    on_update = function() end, -- To be implemented
    on_render = function() end, -- To be implemented
    on_render_menu = function() end, -- To be implemented
    on_render_control_panel = function(_) return _ end -- To be implemented
}
