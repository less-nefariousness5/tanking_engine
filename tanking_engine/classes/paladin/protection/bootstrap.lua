-- Protection Paladin specialization bootstrap

-- Initialize namespace
TankEngine.paladin_protection = TankEngine.paladin_protection or {}

-- Load modules
require("classes/paladin/protection/self_healing")

-- Define enums for resources if not already defined
if not TankEngine.enums then
    TankEngine.enums = {}
    TankEngine.enums.power_type = {
        HOLYPOWER = 9,
        RAGE = 1,
        FURY = 17,
        PAIN = 18,
    }
end

-- Return spec configuration
---@type SpecConfig
return {
    spec_id = 1, -- Protection spec ID
    class_id = 2, -- Paladin class ID
    on_update = function() end, -- To be implemented
    on_render = function() end, -- To be implemented
    on_render_menu = function() end, -- To be implemented
    on_render_control_panel = function(_) return _ end -- To be implemented
}
