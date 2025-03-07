-- Load initialization helper first
local initialization = require("core/initialization")

-- Core modules are loaded in the initialization sequence

-- Initialize modules
local modules = require("core/modules/index")

-- Initialize the tanking engine core
local function initialize()
    core.log("Initializing Tanking Engine Core...")
    
    -- Use the initialization helper for proper dependency management
    if not initialization.initialize_core() then
        core.log_error("Core initialization failed")
        return false
    end
    
    -- Initialize modules
    local modules_success, _ = initialization.initialize_modules()
    if not modules_success then
        core.log_warning("Some modules failed to initialize - continuing with partial functionality")
    end
    
    core.log("Tanking Engine Core initialized successfully")
    return true
end

-- Export core interface
return {
    initialize = initialize,
    modules = modules
}
