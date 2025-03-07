---@type enums
local enums = require("shared/enums")

---Checks whether the current specialization is supported by the tanking engine
---@param player_class number
---@param player_spec_id number
---@return boolean
function TankEngine.entry_helper.check_spec(player_class, player_spec_id)
    local spec_enum = enums.class_spec_id.get_specialization_enum(player_class, player_spec_id)
    if not TankEngine.entry_helper.allowed_specs[spec_enum] then
        return false
    end
    
    -- Initialize spec config with default values
    TankEngine.spec_config = {
        class_id = player_class,
        spec_id = player_spec_id,
        on_update = function() end,
        on_render = function() end,
        on_render_menu = function() end,
        on_render_control_panel = function(_) return _ end
    }
    
    return true
end
