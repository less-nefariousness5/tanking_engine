---@type enums
local enums = require("shared/enums")

---Loads the module for the player's tank specialization
---@return boolean
function TankEngine.entry_helper.load_spec_module()
    ---@type boolean, SpecConfig
    local success, module = pcall(require,
        "classes/" ..
        TankEngine.entry_helper.class_spec_map
        [enums.class_spec_id.get_specialization_enum(TankEngine.spec_config.class_id, TankEngine.spec_config.spec_id)] ..
        "/bootstrap")
    
    if success then
        TankEngine.spec_config = module
        return true
    end
    
    core.log("Failed to load tank spec module: " .. tostring(module))
    return false
end
