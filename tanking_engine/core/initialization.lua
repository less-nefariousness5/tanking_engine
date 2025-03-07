-- Initialization helper for the Tanking Engine
-- This file provides functions to ensure proper initialization order and error handling

-- Local references to common functions for performance
local pcall = pcall
local require = require
local type = type
local tostring = tostring

-- Create local namespace for initialization helper
local InitializationHelper = {}

-- Dependency tracking
InitializationHelper.initialized_components = {
    core_variables = false,
    core_api = false,
    core_settings = false,
    core_menu = false,
    core_humanizer = false,
    modules_threat_manager = false,
    modules_mitigation = false,
    modules_positioning = false,
    modules_enemy_tracking = false,
    modules_wigs_tracker = false
}

-- Safely require a module with error handling
---@param module_path string The path to the module
---@param component_name string The name of the component for tracking
---@return boolean success Whether the module was loaded successfully
---@return table|string module The loaded module or error message
function InitializationHelper.safe_require(module_path, component_name)
    local success, result = pcall(require, module_path)
    
    if success then
        -- Mark component as initialized if tracking is enabled
        if component_name and InitializationHelper.initialized_components[component_name] ~= nil then
            InitializationHelper.initialized_components[component_name] = true
        end
        
        -- Log success
        core.log("Successfully loaded module: " .. module_path)
    else
        -- Log error
        core.log_error("Failed to load module: " .. module_path .. " - " .. tostring(result))
    end
    
    return success, result
end

-- Check if a component is initialized
---@param component_name string The name of the component to check
---@return boolean is_initialized Whether the component is initialized
function InitializationHelper.is_initialized(component_name)
    return InitializationHelper.initialized_components[component_name] == true
end

-- Check if all required core components are initialized
---@return boolean all_initialized Whether all core components are initialized
function InitializationHelper.are_core_components_initialized()
    return InitializationHelper.is_initialized("core_variables") and
           InitializationHelper.is_initialized("core_api") and
           InitializationHelper.is_initialized("core_settings") and
           InitializationHelper.is_initialized("core_menu") and
           InitializationHelper.is_initialized("core_humanizer")
end

-- Initialize Tanking Engine core components in the correct order
---@return boolean success Whether all core components were initialized successfully
function InitializationHelper.initialize_core()
    core.log("Initializing Tanking Engine core components...")
    
    -- 1. Initialize variables (must be first)
    local vars_success, _ = InitializationHelper.safe_require("core/variables", "core_variables")
    if not vars_success then
        core.log_error("Failed to initialize variables - aborting initialization")
        return false
    end
    
    -- 2. Initialize API
    local api_success, _ = InitializationHelper.safe_require("core/api", "core_api")
    if not api_success then
        core.log_error("Failed to initialize API - aborting initialization")
        return false
    end
    
    -- 3. Initialize settings
    local settings_success, _ = InitializationHelper.safe_require("core/settings", "core_settings")
    if not settings_success then
        core.log_error("Failed to initialize settings - aborting initialization")
        return false
    end
    
    -- 4. Initialize menu system
    local menu_success, _ = InitializationHelper.safe_require("core/menu", "core_menu")
    if not menu_success then
        core.log_error("Failed to initialize menu system - aborting initialization")
        return false
    end
    
    -- 5. Initialize humanizer
    local humanizer_success, _ = InitializationHelper.safe_require("core/humanizer", "core_humanizer")
    if not humanizer_success then
        core.log_error("Failed to initialize humanizer - aborting initialization")
        return false
    end
    
    core.log("All core components initialized successfully")
    return true
end

-- Initialize all Tank Engine modules
---@return boolean success Whether all modules were initialized successfully
---@return table loaded_modules Table of successfully loaded modules
function InitializationHelper.initialize_modules()
    core.log("Initializing Tanking Engine modules...")
    
    local module_paths = {
        { path = "core/modules/threat_manager/index", name = "modules_threat_manager" },
        { path = "core/modules/mitigation/index", name = "modules_mitigation" },
        { path = "core/modules/positioning/index", name = "modules_positioning" },
        { path = "core/modules/enemy_tracking/index", name = "modules_enemy_tracking" },
        { path = "core/modules/wigs_tracker/index", name = "modules_wigs_tracker" }
    }
    
    local loaded_modules = {}
    local all_successful = true
    
    for _, module_info in ipairs(module_paths) do
        local success, module = InitializationHelper.safe_require(module_info.path, module_info.name)
        
        if success then
            loaded_modules[module_info.name] = module
            -- Add to global loaded modules if it has a valid interface
            if type(module) == "table" then
                table.insert(TankEngine.loaded_modules, module)
            end
        else
            all_successful = false
            -- Log failure but continue with other modules
            core.log_error("Failed to load module: " .. module_info.name .. " - continuing initialization")
        end
    end
    
    if all_successful then
        core.log("All modules initialized successfully")
    else
        core.log("Some modules failed to initialize")
    end
    
    return all_successful, loaded_modules
end

-- Initialize class-specific module
---@param class_id number The class ID
---@param spec_id number The specialization ID
---@return boolean success Whether the class module was initialized successfully
---@return table|nil spec_module The loaded spec module or nil if failed
function InitializationHelper.initialize_class_module(class_id, spec_id)
    core.log("Initializing class module for class " .. tostring(class_id) .. ", spec " .. tostring(spec_id))
    
    -- Make sure entry_helper is available
    if not TankEngine.entry_helper then
        core.log_error("Entry helper not initialized - can't load class module")
        return false, nil
    end
    
    -- Make sure we have a valid class/spec map
    if not TankEngine.entry_helper.class_spec_map then
        core.log_error("Class/spec map not initialized - can't load class module")
        return false, nil
    end
    
    -- Check if spec is supported
    local spec_enum = TankEngine.api and TankEngine.api.enums and 
                     TankEngine.api.enums.class_spec_id and 
                     TankEngine.api.enums.class_spec_id.get_specialization_enum and
                     TankEngine.api.enums.class_spec_id.get_specialization_enum(class_id, spec_id)
    
    if not spec_enum then
        core.log_error("Failed to get specialization enum for class " .. tostring(class_id) .. ", spec " .. tostring(spec_id))
        return false, nil
    end
    
    local module_path = "classes/" .. TankEngine.entry_helper.class_spec_map[spec_enum] .. "/bootstrap"
    
    local success, module = pcall(require, module_path)
    if success then
        core.log("Successfully loaded class module: " .. module_path)
        return true, module
    else
        core.log_error("Failed to load class module: " .. module_path .. " - " .. tostring(module))
        return false, nil
    end
end

-- Full initialization sequence for the Tanking Engine
---@return boolean success Whether the initialization was successful
function InitializationHelper.initialize_tank_engine()
    core.log("Starting full Tanking Engine initialization...")
    
    -- 1. Initialize core components
    if not InitializationHelper.initialize_core() then
        core.log_error("Failed to initialize core components - aborting initialization")
        return false
    end
    
    -- 2. Initialize modules
    local modules_success, _ = InitializationHelper.initialize_modules()
    if not modules_success then
        core.log("Some modules failed to initialize - continuing with partial functionality")
        -- Continue anyway, as we can function with partial module initialization
    end
    
    -- 3. Get player info for spec module initialization
    local local_player = core.object_manager.get_local_player()
    if not local_player then
        core.log_error("Failed to get local player - aborting initialization")
        return false
    end
    
    local player_class = local_player:get_class()
    local player_spec_id = core.spell_book.get_specialization_id()
    
    -- 4. Initialize class-specific module if player is using a tank spec
    local spec_success, spec_module = InitializationHelper.initialize_class_module(player_class, player_spec_id)
    
    if spec_success and spec_module then
        TankEngine.spec_config = spec_module
        core.log("Successfully initialized spec module for class " .. tostring(player_class) .. ", spec " .. tostring(player_spec_id))
    else
        core.log_warning("No compatible tank spec detected or failed to load spec module")
        -- Continue anyway, as we might just not be in a tank spec
    end
    
    core.log("Tanking Engine initialization complete")
    return true
end

-- Add initialization helper to TankEngine
TankEngine.initialization = InitializationHelper

return InitializationHelper
