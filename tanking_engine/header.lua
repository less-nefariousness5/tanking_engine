local version = require("version")

if false then
    return {
        name = "Tanking Engine",
        version = version:toString(),
        author = "TankDev",
        load = false
    }
end

-- Create global namespace for our tanking engine
TankEngine = {
    ---@type SpecConfig
    spec_config = nil,
    ---@type ModuleConfig[]
    loaded_modules = {},
    -- Make version accessible globally
    version = version
}

require("entry/index")

local plugin = {
    name = "Tanking Engine",
    version = version:toString(),
    author = "TankDev",
    load = true
}

-- Get local player
local local_player = core.object_manager.get_local_player()
if not local_player then
    plugin["load"] = false
    return plugin
end

-- Get player info
local player_class = local_player:get_class()
local player_spec_id = core.spell_book.get_specialization_id()

if TankEngine.entry_helper.check_spec(player_class, player_spec_id) then
    return plugin
end

-- Spec not supported or module failed to load
plugin["load"] = false
return plugin
