local tag = "mitigation_"
local name = "Mitigation"

---@type color
local color = require("shared/color")

---@type on_render_menu
function TankEngine.modules.mitigation.menu.on_render_menu()
    TankEngine.modules.mitigation.menu.tree:render(name, function()
        -- Mitigation Management
        TankEngine.menu.mitigation.major_cooldown_threshold:render("Major CD Threshold (%)", 
            "Health percentage threshold for using major defensive cooldowns")
        
        TankEngine.menu.mitigation.minor_cooldown_threshold:render("Minor CD Threshold (%)", 
            "Health percentage threshold for using minor defensive abilities")
        
        TankEngine.menu.mitigation.predictive_mitigation:render("Predictive Mitigation", 
            "Use defensives preemptively based on predicted damage")
        
        TankEngine.menu.mitigation.active_mitigation_overlap:render("Active Mitigation Overlap %",
            "How much to overlap active mitigation abilities (higher = less downtime)")
        
        TankEngine.menu.mitigation.save_for_spikes:render("Save CDs for Damage Spikes", 
            "Save major defensives for predicted damage spikes")
        
        -- Healing Awareness Settings
        local healing_tree = TankEngine.menu.tree_node()
        healing_tree:render("Healing Awareness", function()
            TankEngine.menu.mitigation.consider_incoming_heals:render("Consider Incoming Heals", 
                "Delay using defensive cooldowns when sufficient healing is incoming")
            
            TankEngine.menu.mitigation.heal_significance_threshold:render("Heal Significance Threshold (%)", 
                "Minimum healing impact required to delay cooldown usage (% of max health)")
        end)
        
        -- Advanced Mitigation Settings Tree
        local advanced_tree = TankEngine.menu.tree_node()
        advanced_tree:render("Advanced Mitigation Settings", function()
            -- Defensive ability list
            local abilities_tree = TankEngine.menu.tree_node()
            abilities_tree:render("Defensive Abilities", function()
                -- Display registered defensive abilities
                for _, ability in pairs(TankEngine.modules.mitigation.abilities) do
                    core.menu.label(ability.name)
                    -- TODO: Add individual ability settings if needed
                end
            end)
        end)
    end)
end
