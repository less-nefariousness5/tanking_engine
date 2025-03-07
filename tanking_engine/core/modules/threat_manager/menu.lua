local tag = "threat_manager_"
local name = "Threat Manager"

---@type color
local color = require("shared/color")

---@type on_render_menu
function TankEngine.modules.threat_manager.menu.on_render_menu()
    TankEngine.modules.threat_manager.menu.tree:render(name, function()
        -- Threat Management
        TankEngine.menu.threat.prioritize_loose_mobs:render("Prioritize Loose Mobs", 
            "Prioritize mobs that are attacking non-tanks")
        
        TankEngine.menu.threat.taunt_threshold:render("Taunt Threshold", 
            "Priority threshold for when to use taunt (higher values = more selective)")
        
        TankEngine.menu.threat.auto_taunt:render("Auto Taunt", 
            "Automatically taunt high-priority targets")
        
        TankEngine.menu.threat.target_swap_threshold:render("Target Swap Threshold", 
            "Priority threshold for when to automatically swap targets (higher values = more selective)")
        
        -- Advanced Threat Settings Tree
        local advanced_tree = TankEngine.menu.tree_node()
        advanced_tree:render("Advanced Threat Settings", function()
            -- Future advanced threat settings can be added here
        end)
    end)
end
