---@type color
local color = require("shared/color")

---@alias on_render_menu fun()

---@type on_render_menu
function TankEngine.entry_helper.on_render_menu()
    -- Ensure TankEngine and menu are initialized
    if not TankEngine then
        core.log_error("TankEngine is nil in on_render_menu")
        return
    end
    
    if not TankEngine.menu then
        core.log_error("TankEngine.menu is nil in on_render_menu")
        return
    end
    
    -- Ensure main tree exists
    if not TankEngine.menu.main_tree then
        core.log_error("Main tree node is nil in on_render_menu")
        -- Try to initialize the main tree if it doesn't exist
        TankEngine.menu.main_tree = core.menu.tree_node()
        if not TankEngine.menu.main_tree then
            core.log_error("Failed to create main tree node")
            return
        end
    end

    -- Safely call render with pcall to catch any errors
    local success, err = pcall(function()
        TankEngine.menu.main_tree:render("Tanking Engine", function()
            -- Main enable/disable toggle
            if TankEngine.menu.enable_script_check then
                TankEngine.menu.enable_script_check:render("Enable Script")
            else
                core.log_error("Enable script checkbox is nil in on_render_menu")
                return
            end
            
            -- Only show additional options when enabled
            if not TankEngine.settings or not TankEngine.settings.is_enabled or not TankEngine.settings.is_enabled() then 
                return 
            end

            -- Humanizer settings tree
            if TankEngine.menu.humanizer and TankEngine.menu.humanizer.tree then
                TankEngine.menu.humanizer.tree:render("Humanizer", function()
                    -- Basic humanizer settings
                    if TankEngine.menu.humanizer.enable_humanizer then
                        TankEngine.menu.humanizer.enable_humanizer:render("Enable Humanizer", 
                            "Adds random delays between actions to simulate human behavior")
                    end
                    
                    if TankEngine.settings.humanizer and TankEngine.settings.humanizer.is_enabled and TankEngine.settings.humanizer.is_enabled() then
                        if TankEngine.menu.humanizer.min_delay then
                            TankEngine.menu.humanizer.min_delay:render("Min delay", 
                                "Minimum delay in milliseconds until next action")
                        end
                        
                        if TankEngine.menu.humanizer.max_delay then
                            TankEngine.menu.humanizer.max_delay:render("Max delay", 
                                "Maximum delay in milliseconds until next action")
                        end
                        
                        -- Advanced randomization (jitter) settings
                        if TankEngine.menu.humanizer.jitter and TankEngine.menu.humanizer.jitter.enable_jitter then
                            TankEngine.menu.humanizer.jitter.enable_jitter:render("Enable Advanced Randomization",
                                "Adds sophisticated timing variations to create more natural, human-like behavior. This feature applies percentage-based randomization to delays and adapts to your current latency.")
                        end
                        
                        if TankEngine.settings.humanizer.jitter and TankEngine.settings.humanizer.jitter.is_enabled and TankEngine.settings.humanizer.jitter.is_enabled() then
                            if TankEngine.menu.humanizer.jitter.base_jitter then
                                TankEngine.menu.humanizer.jitter.base_jitter:render("Base Randomization %",
                                    "The baseline percentage of randomization applied to all delays. Higher values create more variation.")
                            end
                            
                            if TankEngine.menu.humanizer.jitter.latency_jitter then
                                TankEngine.menu.humanizer.jitter.latency_jitter:render("Adaptive Latency %",
                                    "Additional randomization that scales with your current network latency. Helps adapt timing to your connection quality.")
                            end
                            
                            if TankEngine.menu.humanizer.jitter.max_jitter then
                                TankEngine.menu.humanizer.jitter.max_jitter:render("Maximum Variation %",
                                    "Maximum total randomization percentage allowed. Prevents excessive variation while maintaining natural behavior.")
                            end
                        end
                    end
                end)
            else
                core.log_error("Humanizer tree node is nil in on_render_menu")
            end

            -- Module-specific menus
            if TankEngine.loaded_modules then
                for _, module in pairs(TankEngine.loaded_modules) do
                    if module and module.on_render_menu then
                        local success, err = pcall(module.on_render_menu)
                        if not success then
                            core.log_error("Error in module on_render_menu: " .. tostring(err))
                        end
                    end
                end
            end
            
            -- Spec-specific menu
            if TankEngine.spec_config and TankEngine.spec_config.on_render_menu then
                local success, err = pcall(TankEngine.spec_config.on_render_menu)
                if not success then
                    core.log_error("Error in spec_config on_render_menu: " .. tostring(err))
                end
            end
        end)
    end)
    
    if not success then
        core.log_error("Error in on_render_menu: " .. tostring(err))
    end
end
