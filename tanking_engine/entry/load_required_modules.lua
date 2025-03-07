-- Define required modules for the tanking engine
local required_modules = {
    "core/modules/threat_manager/index",
    "core/modules/mitigation/index",
    "core/modules/positioning/index",
    "core/modules/enemy_tracking/index",
    "core/modules/wigs_tracker/index"
}

---Loads all required modules for the tanking engine
---@return boolean
function TankEngine.entry_helper.load_required_modules()
    require("core/index")
    
    for _, module_path in ipairs(required_modules) do
        local success, module = pcall(require, module_path)
        if success then
            table.insert(TankEngine.loaded_modules, module)
        else
            core.log("Failed to load required module: " .. module_path)
            return false
        end
    end
    
    return true
end
