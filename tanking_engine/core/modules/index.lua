-- Initialize modules namespace
TankEngine.modules = {}

-- Load all module definitions
local threat_manager = require("core/modules/threat_manager/index")
local mitigation = require("core/modules/mitigation/index")
local positioning = require("core/modules/positioning/index")
local enemy_tracking = require("core/modules/enemy_tracking/index")
local wigs_tracker = require("core/modules/wigs_tracker/index")

-- Register all modules
local modules = {
    threat_manager = threat_manager,
    mitigation = mitigation,
    positioning = positioning,
    enemy_tracking = enemy_tracking,
    wigs_tracker = wigs_tracker
}

-- Initialize module callbacks
local function initialize_callbacks()
    -- Register update callbacks
    for name, module in pairs(modules) do
        if module.on_update then
            core.log("Registering update callback for module: " .. name)
            TankEngine.api.register_module_update(name, module.on_update)
        end
        
        if module.on_fast_update then
            core.log("Registering fast update callback for module: " .. name)
            TankEngine.api.register_module_fast_update(name, module.on_fast_update)
        end
        
        if module.on_render then
            core.log("Registering render callback for module: " .. name)
            TankEngine.api.register_module_render(name, module.on_render)
        end
        
        if module.on_render_menu then
            core.log("Registering menu callback for module: " .. name)
            TankEngine.api.register_module_menu(name, module.on_render_menu)
        end
        
        -- Call initialize function if it exists
        if module.initialize then
            core.log("Initializing module: " .. name)
            module.initialize()
        end
    end
end

-- Module interface
return {
    initialize = initialize_callbacks,
    modules = modules
} 