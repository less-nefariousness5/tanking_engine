-- Index file for common utilities

-- Import API enums
local api_enums = require("common/enums")

-- Import tank-specific enums
local tank_enums = require("shared/tank_enums")

-- Combine enums
local combined_enums = {}
for k, v in pairs(api_enums) do
    combined_enums[k] = v
end
for k, v in pairs(tank_enums) do
    combined_enums[k] = v
end

local common = {
    enums = combined_enums,
    utils = require("shared/utils"),
    combat_utils = require("shared/combat_utils"),
    math_utils = require("shared/math_utils")
}

return common 