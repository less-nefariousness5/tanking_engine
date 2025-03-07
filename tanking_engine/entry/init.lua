---Initializes the tanking engine and loads required modules
---@return boolean
function TankEngine.entry_helper.init()
    core.log("Initializing Tanking Engine...")
    
    -- Use pcall for error handling
    local success, err = pcall(function()
        -- Load required modules
        if not TankEngine.entry_helper.load_required_modules() then
            core.log("Failed to load required tanking engine modules")
            return false
        end
        
        -- Initialize core
        local core_module = require("core/index")
        if not core_module.initialize() then
            core.log("Failed to initialize tanking engine core")
            return false
        end
        
        -- Load spec-specific module (this is now handled in initialization.lua)
        -- but we keep this for backwards compatibility and error checking
        local spec_module_result = TankEngine.entry_helper.load_spec_module()
        if not spec_module_result then
            core.log_warning("No compatible tank spec detected or failed to load spec module")
            -- Continue anyway - we might just not be in a tank spec
        end
        
        return true
    end)
    
    if not success then
        core.log_error("Error during Tanking Engine initialization: " .. tostring(err))
        return false
    end
    
    if err == false then
        core.log("Tanking Engine initialization failed")
        return false
    end
    
    core.log("Tanking Engine initialized successfully")
    return true
end
