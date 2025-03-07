---@type buff_manager
local buff_manager = require("common/modules/buff_manager")
---@type combat_forecast
local combat_forecast = require("common/modules/combat_forecast")
---@type health_prediction
local health_prediction = require("common/modules/health_prediction")
---@type spell_helper
local spell_helper = require("common/utility/spell_helper")
---@type spell_queue
local spell_queue = require("common/modules/spell_queue")
---@type unit_helper
local unit_helper = require("common/utility/unit_helper")
---@type target_selector
local target_selector = require("common/modules/target_selector")
---@type plugin_helper
local plugin_helper = require("common/utility/plugin_helper")
---@type control_panel_helper
local control_panel_helper = require("common/utility/control_panel_helper")
---@type key_helper
local key_helper = require("common/utility/key_helper")
---@type utils
local utils = require("shared/utils")

-- Import tank-specific utilities
local common = require("shared/index")
local tank_utils = require("shared/utils")
local combat_utils = require("shared/combat_utils")
local math_utils = require("shared/math_utils")
local enums = common.enums

-- Module callback registrations
local module_update_callbacks = {}
local module_fast_update_callbacks = {}
local module_render_callbacks = {}
local module_menu_callbacks = {}

-- Centralized API access for the tanking engine
TankEngine.api = {
    -- Core API modules
    buff_manager = buff_manager,
    combat_forecast = combat_forecast,
    health_prediction = health_prediction,
    spell_helper = spell_helper,
    spell_queue = spell_queue,
    unit_helper = unit_helper,
    target_selector = target_selector,
    plugin_helper = plugin_helper,
    control_panel_helper = control_panel_helper,
    key_helper = key_helper,
    graphics = core.graphics,
    
    -- Custom tanking-specific API helpers
    utils = utils,
    tank_utils = tank_utils,
    combat_utils = combat_utils,
    math_utils = math_utils,
    enums = enums,
    
    -- Convenience functions
    
    ---Check if a spell can be cast on the current target or without a target
    ---@param spell_id number The spell ID to check
    ---@return boolean castable Whether the spell can be cast
    can_cast_spell = function(spell_id)
        -- Get player safely
        local me = TankEngine.variables and TankEngine.variables.me or core.object_manager.get_local_player()
        if not me or not me:is_valid() then return false end
        
        -- Get target safely using the new safe getter
        local target = nil
        if TankEngine.variables and TankEngine.variables.get_safe_target then
            target = TankEngine.variables.get_safe_target()
        end
        
        -- If no valid target, check if spell can be cast without a target
        if not target then
            -- Some spells can be cast without a target (like Shield Block)
            -- For these, we'll use the player as the target
            return spell_helper:is_spell_castable(spell_id, me, me, false, false)
        end
        
        -- Check if spell can be cast on the target
        return spell_helper:is_spell_castable(spell_id, me, target, false, false)
    end,
    
    ---Cast a spell on a target or at a position
    ---@param spell_id number The spell ID to cast
    ---@param target? game_object|vec3 The target unit or position (optional)
    ---@param priority? number The priority of the spell (1-9, default: 5)
    ---@param message? string A message for debugging (optional)
    ---@return boolean success Whether the spell was queued successfully
    cast_spell = function(spell_id, target, priority, message)
        -- Validate spell_id
        if not spell_id or type(spell_id) ~= "number" then
            core.log_error("TankEngine: Invalid spell_id in cast_spell: " .. tostring(spell_id))
            return false
        end
        
        -- Set default priority if not provided
        priority = priority or 5
        
        -- Set default message if not provided
        message = message or "TankEngine: Casting " .. spell_id
        
        -- Handle target parameter
        if target then
            if type(target) == "userdata" then -- Game object target
                -- Validate target is valid
                if not target:is_valid() then
                    core.log_error("TankEngine: Invalid target in cast_spell: " .. tostring(spell_id))
                    return false
                end
                spell_queue:queue_spell_target(spell_id, target, priority, message)
            else -- Position target
                spell_queue:queue_spell_position(spell_id, target, priority, message)
            end
        else
            -- No target, cast on self
            local me = TankEngine.variables and TankEngine.variables.me or core.object_manager.get_local_player()
            if not me or not me:is_valid() then
                core.log_error("TankEngine: Invalid player in cast_spell: " .. tostring(spell_id))
                return false
            end
            spell_queue:queue_spell_target(spell_id, me, priority, message)
        end
        return true
    end,
    
    -- Register a module update callback
    ---@param module_name string The name of the module
    ---@param callback function The update callback function
    register_module_update = function(module_name, callback)
        module_update_callbacks[module_name] = callback
    end,
    
    -- Register a module fast update callback
    ---@param module_name string The name of the module
    ---@param callback function The fast update callback function
    register_module_fast_update = function(module_name, callback)
        module_fast_update_callbacks[module_name] = callback
    end,
    
    -- Register a module render callback
    ---@param module_name string The name of the module
    ---@param callback function The render callback function
    register_module_render = function(module_name, callback)
        module_render_callbacks[module_name] = callback
    end,
    
    -- Register a module menu callback
    ---@param module_name string The name of the module
    ---@param callback function The menu callback function
    register_module_menu = function(module_name, callback)
        module_menu_callbacks[module_name] = callback
    end,
    
    -- Execute all module update callbacks
    execute_module_updates = function()
        for _, callback in pairs(module_update_callbacks) do
            callback()
        end
    end,
    
    -- Execute all module fast update callbacks
    execute_module_fast_updates = function()
        for _, callback in pairs(module_fast_update_callbacks) do
            callback()
        end
    end,
    
    -- Execute all module render callbacks
    execute_module_renders = function()
        for _, callback in pairs(module_render_callbacks) do
            callback()
        end
    end,
    
    -- Execute all module menu callbacks
    execute_module_menus = function()
        for _, callback in pairs(module_menu_callbacks) do
            callback()
        end
    end,
    
    -- Tank-specific API functions
    
    -- Get the best defensive cooldown to use based on the current situation
    ---@param health_percent number Current health percentage (0-100)
    ---@param enemy_count number Number of enemies in combat
    ---@param is_boss boolean Whether fighting a boss
    ---@param available_cooldowns table List of available defensive cooldowns
    ---@return number|nil spell_id The spell ID to use, or nil if none
    get_best_defensive_cooldown = function(health_percent, enemy_count, is_boss, available_cooldowns)
        -- Check if we're in a dangerous situation
        local is_dangerous = combat_utils.is_dangerous_situation(health_percent, enemy_count, is_boss)
        
        if not is_dangerous then
            return nil
        end
        
        -- Get recent damage events (placeholder - would need actual implementation)
        local damage_events = {}
        
        -- Analyze damage type and pattern
        local damage_type = combat_utils.analyze_damage_type(damage_events)
        local damage_pattern = combat_utils.analyze_damage_pattern(damage_events, 3)
        
        -- Prioritize cooldowns
        local prioritized = combat_utils.prioritize_defensive_cooldowns(
            available_cooldowns, health_percent, damage_type, damage_pattern
        )
        
        -- Return the highest priority cooldown that's available
        for _, cooldown in ipairs(prioritized) do
            if TankEngine.api.can_cast_spell(cooldown.spell_id) then
                return cooldown.spell_id
            end
        end
        
        return nil
    end,
    
    -- Get the best target to taunt based on threat analysis
    ---@param range number Optional range to check (defaults to 30)
    ---@return game_object|nil target The best target to taunt, or nil if none
    get_best_taunt_target = function(range)
        range = range or 30
        local enemies = tank_utils.get_enemies_in_combat(range)
        return tank_utils.get_best_taunt_target(enemies)
    end,
    
    -- Check if an interrupt should be used on a target
    ---@param target game_object The target unit
    ---@param interrupt_spells table List of available interrupt spells
    ---@return number|nil spell_id The spell ID to use for interrupting, or nil if none
    should_interrupt = function(target, interrupt_spells)
        return combat_utils.should_interrupt(target, interrupt_spells)
    end,
    
    -- Calculate the optimal position for tanking
    ---@param enemies table List of enemy units
    ---@param strategy number The positioning strategy to use
    ---@return number x, number y, number z The optimal position coordinates
    calculate_optimal_position = function(enemies, strategy)
        return tank_utils.calculate_optimal_position(enemies, strategy)
    end,
    
    -- Analyze group positioning and determine if tank needs to reposition
    ---@param group_members table List of group member units
    ---@param enemies table List of enemy units
    ---@return boolean should_reposition Whether the tank should reposition
    ---@return number strategy The positioning strategy to use
    analyze_group_positioning = function(group_members, enemies)
        return combat_utils.analyze_group_positioning(group_members, enemies)
    end
}

-- Return the API for module use
return TankEngine.api