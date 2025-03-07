-- Protection Warrior specialization bootstrap
---@type spell_helper
local spell_helper = require("common/utility/spell_helper")
---@type spell_queue
local spell_queue = require("common/modules/spell_queue")

-- Initialize namespace
TankEngine.warrior_protection = TankEngine.warrior_protection or {}

-- Import required modules
---@type color
local color = require("common/color")
---@type vec3
local vec3 = require("common/geometry/vector_3")

-- Initialize API if not already done
TankEngine.api = TankEngine.api or {}

-- Load modules
require("classes/warrior/protection/self_healing")
require("classes/warrior/protection/defensives")
require("classes/warrior/protection/utility")
require("classes/warrior/protection/menu")

-- Define enums for resources if not already defined
if not TankEngine.enums then
    TankEngine.enums = {}
    TankEngine.enums.power_type = {
        RAGE = 1,
        FURY = 17,
        PAIN = 18,
        HOLYPOWER = 9,
    }
end

-- Main update function
local function on_update()
    -- Check if module is enabled
    if not TankEngine.warrior_protection.menu.elements.enable_module:get_state() then
        return
    end
    
    -- Get player and target
    local me = core.object_manager.get_local_player()
    if not me or me:is_dead() then return end
    
    -- Update variables
    TankEngine.variables = TankEngine.variables or {}
    TankEngine.variables.me = me
    
    -- Set target as a function to be compatible with threat_manager
    TankEngine.variables.target = function()
        return me:get_target()
    end
    
    -- Initialize predicted incoming damage and damage type
    TankEngine.variables.predicted_incoming_damage = 0
    TankEngine.variables.incoming_damage_type = "physical"
    
    -- Wrap all potentially dangerous operations in pcall for error handling
    local success, error_msg = pcall(function()
        -- Check if WigsTracker is available and update predicted damage
        if TankEngine.modules and TankEngine.modules.wigs_tracker then
            local should_use_defensive, bar = TankEngine.modules.wigs_tracker.should_use_defensive()
            if should_use_defensive and bar and bar.importance then
                -- Estimate incoming damage based on ability importance
                -- Higher importance = more damage
                local max_health = me:get_max_health()
                TankEngine.variables.predicted_incoming_damage = (bar.importance / 10) * max_health * 0.3
                
                -- Try to determine damage type from ability name
                if bar.text then
                    local text = string.lower(bar.text)
                    if string.find(text, "spell") or string.find(text, "magic") or 
                       string.find(text, "shadow") or string.find(text, "fire") or 
                       string.find(text, "frost") or string.find(text, "arcane") then
                        TankEngine.variables.incoming_damage_type = "magical"
                    end
                end
            end
        end
        
        -- Define enemies_in_melee_range function
        TankEngine.variables.enemies_in_melee_range = function()
            local enemies = core.object_manager.get_all_objects()
            local count = 0
            local melee_range = 8 -- yards
            
            for _, enemy in ipairs(enemies) do
                if enemy:is_unit() and me:can_attack(enemy) and not enemy:is_dead() and 
                   TankEngine.variables.get_distance_to(me, enemy) <= melee_range then
                    count = count + 1
                end
            end
            
            return count
        end
        
        -- Check for defensive cooldowns first
        if TankEngine.warrior_protection.menu.elements.use_defensives and 
           TankEngine.warrior_protection.menu.elements.use_defensives:get_state() and
           TankEngine.warrior_protection.check_defensive_cooldowns() then
            -- A defensive cooldown was used, continue with normal rotation
        end
        
        -- Check for taunt targets
        local taunt_target = TankEngine.warrior_protection.get_best_taunt_target()
        if taunt_target and TankEngine.api.can_cast_spell(TankEngine.warrior_protection.spells.taunt) then
            TankEngine.api.cast_spell(TankEngine.warrior_protection.spells.taunt, taunt_target)
            return
        end
        
        -- Execute rotation (to be implemented in rotation.lua)
        if TankEngine.warrior_protection.execute_rotation then
            TankEngine.warrior_protection.execute_rotation()
        end
    end)
    
    -- Log any errors that occurred during update
    if not success then
        core.log_error("TankEngine Protection Warrior Error: " .. tostring(error_msg))
    end
end

-- Main render function
local function on_render()
    -- Check if module is enabled
    if not TankEngine.warrior_protection.menu.elements.enable_module:get_state() then
        return
    end
    
    -- Render debug information if enabled
    if TankEngine.warrior_protection.menu.elements.show_debug_info and 
       TankEngine.warrior_protection.menu.elements.show_debug_info:get_state() then
        -- Render defensive cooldown information
        local y_offset = 100
        local me = TankEngine.variables.me
        
        if me then
            -- Display current health
            local current_health = me:get_health()
            local max_health = me:get_max_health()
            local health_percent = (current_health / max_health) * 100
            core.graphics.text_3d(
                string.format("Health: %.1f%%", health_percent),
                vec3.new(0, y_offset, 0),
                20, -- font size
                color.new(255, 255 - health_percent * 2.55, 255 - health_percent * 2.55, 255),
                true -- centered
            )
            y_offset = y_offset + 15
            
            -- Display current rage
            local rage = me:get_power(TankEngine.enums.power_type.RAGE)
            core.graphics.text_3d(
                string.format("Rage: %d", rage),
                vec3.new(0, y_offset, 0),
                20, -- font size
                color.new(255, 0, 0, 255),
                true -- centered
            )
            y_offset = y_offset + 15
            
            -- Display Shield Block charges
            local shield_block_charges = core.spell_book.get_spell_charge(TankEngine.warrior_protection.spells.shield_block) or 0
            core.graphics.text_3d(
                string.format("Shield Block Charges: %d", shield_block_charges),
                vec3.new(0, y_offset, 0),
                20, -- font size
                color.new(255, 255, 0, 255),
                true -- centered
            )
            y_offset = y_offset + 15
            
            -- Display defensive cooldowns
            for _, defensive in ipairs(TankEngine.warrior_protection.defensives.major) do
                local cooldown = core.spell_book.get_spell_cooldown(defensive.spell_id)
                local color_val = cooldown > 0 and color.new(255, 0, 0, 255) or color.new(0, 255, 0, 255)
                
                core.graphics.text_3d(
                    string.format("%s: %.1fs", defensive.name, cooldown),
                    vec3.new(0, y_offset, 0),
                    20, -- font size
                    color_val,
                    true -- centered
                )
                y_offset = y_offset + 15
            end
        end
    end
end

-- Menu render function
local function on_render_menu()
    -- Call the menu render function
    if TankEngine.warrior_protection.menu.on_render_menu then
        TankEngine.warrior_protection.menu.on_render_menu()
    end
end

-- Control panel render function
local function on_render_control_panel(control_panel_elements)
    -- Add Protection Warrior elements to the control panel
    local control_panel_utility = require("common/utility/control_panel_helper")
    
    -- Create toggle elements with proper keybind objects
    -- The error occurs because we're not providing actual keybind objects
    
    -- Create keybind objects if they don't exist
    if not TankEngine.warrior_protection.keybinds then
        TankEngine.warrior_protection.keybinds = {
            enable_toggle = core.menu.keybind(7, false, "warrior_prot_enable_toggle"),
            defensives_toggle = core.menu.keybind(7, false, "warrior_prot_defensives_toggle")
        }
    end
    
    -- Now use these keybind objects
    local enable_toggle = {
        name = "Protection Warrior",
        keybind = TankEngine.warrior_protection.keybinds.enable_toggle,
        get_state = function() 
            return TankEngine.warrior_protection.menu.elements.enable_module:get_state() 
        end,
        set_state = function(state) 
            TankEngine.warrior_protection.menu.elements.enable_module:set(state) 
        end
    }
    
    local defensives_toggle = {
        name = "Use Defensives",
        keybind = TankEngine.warrior_protection.keybinds.defensives_toggle,
        get_state = function() 
            return TankEngine.warrior_protection.menu.elements.use_defensives and 
                   TankEngine.warrior_protection.menu.elements.use_defensives:get_state() or true
        end,
        set_state = function(state) 
            if TankEngine.warrior_protection.menu.elements.use_defensives then
                TankEngine.warrior_protection.menu.elements.use_defensives:set(state)
            end
        end
    }
    
    -- Insert elements into control panel
    control_panel_utility:insert_toggle_(control_panel_elements, enable_toggle.name, enable_toggle.keybind, false)
    control_panel_utility:insert_toggle_(control_panel_elements, defensives_toggle.name, defensives_toggle.keybind, false)
    
    return control_panel_elements
end

-- Initialize function
local function initialize()
    -- Initialize menu
    if TankEngine.warrior_protection.menu.initialize then
        TankEngine.warrior_protection.menu.initialize()
    end
    
    -- Initialize WigsTracker integration
    if TankEngine.warrior_protection.integrate_with_wigs_tracker then
        TankEngine.warrior_protection.integrate_with_wigs_tracker()
    end
    
    -- Log initialization
    core.log("[Protection Warrior] Module initialized")
end

-- Return spec configuration
---@type SpecConfig
return {
    spec_id = 3, -- Protection spec ID
    class_id = 1, -- Warrior class ID
    on_update = on_update,
    on_render = on_render,
    on_render_menu = on_render_menu,
    on_render_control_panel = on_render_control_panel,
    initialize = initialize
}
