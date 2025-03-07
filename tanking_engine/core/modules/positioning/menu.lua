local tag = "positioning_"
local name = "Positioning"

---@type color
local color = require("shared/color")

---@type on_render_menu
function TankEngine.modules.positioning.menu.on_render_menu()
    TankEngine.modules.positioning.menu.tree:render(name, function()
        -- Movement Settings
        TankEngine.menu.movement.auto_position:render("Auto Position", 
            "Automatically optimize tank positioning")
        
        TankEngine.menu.movement.kiting_threshold:render("Kiting Threshold (%)", 
            "Health percentage threshold for when to start kiting")
        
        TankEngine.menu.movement.maintain_range:render("Maintain Range", 
            "Try to maintain optimal range from enemies")
        
        -- Advanced Positioning Settings Tree
        local advanced_tree = TankEngine.menu.tree_node()
        advanced_tree:render("Advanced Positioning", function()
            -- Positioning parameters
            TankEngine.modules.positioning.menu.preferred_range:render("Preferred Range", 
                "Preferred distance to keep from enemies")
            
            TankEngine.modules.positioning.menu.max_range:render("Maximum Range", 
                "Maximum distance to consider for positioning")
            
            TankEngine.modules.positioning.menu.kiting_distance:render("Kiting Distance", 
                "Distance to move when kiting")
            
            TankEngine.modules.positioning.menu.safe_zone_radius:render("Safe Zone Radius", 
                "Radius of safe zone to maintain")
            
            -- Visualization options
            TankEngine.modules.positioning.menu.show_positioning:render("Show Positioning", 
                "Visualize recommended positions")
            
            TankEngine.modules.positioning.menu.show_kiting_path:render("Show Kiting Path", 
                "Visualize kiting path when active")
            
            TankEngine.modules.positioning.menu.position_color:render("Position Color", 
                "Color for position visualization")
        end)
    end)
end
