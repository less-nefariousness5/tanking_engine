local tag = "enemy_tracking_"
local name = "Enemy Tracking"

---@type color
local color = require("shared/color")

---@type on_render_menu
function TankEngine.modules.enemy_tracking.menu.on_render_menu()
    -- Check if tree exists before trying to render
    if not TankEngine.modules.enemy_tracking.menu.tree then
        core.log_error("Enemy tracking menu tree is nil")
        return
    end

    TankEngine.modules.enemy_tracking.menu.tree:render(name, function()
        -- Interrupt Settings
        -- Check if menu elements exist before rendering
        if TankEngine.menu.interrupt and TankEngine.menu.interrupt.auto_interrupt then
            TankEngine.menu.interrupt.auto_interrupt:render("Auto Interrupt", 
                "Automatically interrupt high-priority spells")
        end
        
        if TankEngine.menu.interrupt and TankEngine.menu.interrupt.prioritize_dangerous then
            TankEngine.menu.interrupt.prioritize_dangerous:render("Prioritize Dangerous Casts", 
                "Prioritize interrupting dangerous spells over normal ones")
        end
        
        if TankEngine.menu.interrupt and TankEngine.menu.interrupt.save_for_important then
            TankEngine.menu.interrupt.save_for_important:render("Save for Important Interrupts", 
                "Save interrupt cooldown for high-priority casts")
        end
        
        -- Advanced Enemy Tracking Settings Tree
        local advanced_tree = TankEngine.menu.tree_node()
        if advanced_tree then
            advanced_tree:render("Advanced Enemy Tracking", function()
                -- Enemy tracking settings
                if TankEngine.modules.enemy_tracking.menu.max_tracking_distance then
                    TankEngine.modules.enemy_tracking.menu.max_tracking_distance:render("Max Tracking Distance\n", 
                        "Maximum distance to track enemies")
                end
                
                if TankEngine.modules.enemy_tracking.menu.position_history_length then
                    TankEngine.modules.enemy_tracking.menu.position_history_length:render("Position History Length\n", 
                        "Number of positions to remember per enemy")
                end
                
                if TankEngine.modules.enemy_tracking.menu.enable_pathing_prediction then
                    TankEngine.modules.enemy_tracking.menu.enable_pathing_prediction:render("Enable Pathing Prediction", 
                        "Predict enemy movement patterns")
                end
                
                -- Display registered dangerous spells if any
                local dangerous_spells_tree = TankEngine.menu.tree_node()
                if dangerous_spells_tree then
                    dangerous_spells_tree:render("Dangerous Spells", function()
                        local count = 0
                        for spell_id, _ in pairs(TankEngine.modules.enemy_tracking.dangerous_spells or {}) do
                            count = count + 1
                            core.menu.text_input(string.format("Spell ID: %d (Priority: %d)", 
                                spell_id, (TankEngine.modules.enemy_tracking.interrupt_priorities or {})[spell_id] or 0))
                        end
                        
                        if count == 0 then
                            core.menu.text_input("No dangerous spells registered")
                        end
                    end)
                end
            end)
        end
    end)
end
