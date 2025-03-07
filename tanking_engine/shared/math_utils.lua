-- Mathematical utility functions for the Tanking Engine

-- Directly require the enums to avoid circular dependency
local api_enums = require("common/enums")
local tank_enums = require("shared/tank_enums")

-- Combine enums
local enums = {}
for k, v in pairs(api_enums) do
    enums[k] = v
end
for k, v in pairs(tank_enums) do
    enums[k] = v
end

local MathUtils = {}

-- Calculate distance between two points in 3D space
---@param x1 number First point x coordinate
---@param y1 number First point y coordinate
---@param z1 number First point z coordinate
---@param x2 number Second point x coordinate
---@param y2 number Second point y coordinate
---@param z2 number Second point z coordinate
---@return number distance The distance between the points
function MathUtils.distance(x1, y1, z1, x2, y2, z2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2 + (z2 - z1)^2)
end

-- Calculate distance between two points in 2D space (ignoring z-axis)
---@param x1 number First point x coordinate
---@param y1 number First point y coordinate
---@param x2 number Second point x coordinate
---@param y2 number Second point y coordinate
---@return number distance The distance between the points in 2D
function MathUtils.distance_2d(x1, y1, x2, y2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

-- Calculate the angle between two points in 2D space
---@param x1 number First point x coordinate
---@param y1 number First point y coordinate
---@param x2 number Second point x coordinate
---@param y2 number Second point y coordinate
---@return number angle The angle in radians
function MathUtils.angle_between(x1, y1, x2, y2)
    return math.atan2(y2 - y1, x2 - x1)
end

-- Calculate a point at a specific distance and angle from a starting point
---@param x number Starting point x coordinate
---@param y number Starting point y coordinate
---@param angle number The angle in radians
---@param distance number The distance to travel
---@return number new_x, number new_y The coordinates of the new point
function MathUtils.point_at_distance_and_angle(x, y, angle, distance)
    local new_x = x + math.cos(angle) * distance
    local new_y = y + math.sin(angle) * distance
    return new_x, new_y
end

-- Calculate the center point of a group of points
---@param points table Array of points, each with x, y, z coordinates
---@return number center_x, number center_y, number center_z The center point coordinates
function MathUtils.center_point(points)
    if not points or #points == 0 then
        return 0, 0, 0
    end
    
    local sum_x, sum_y, sum_z = 0, 0, 0
    local count = 0
    
    for _, point in ipairs(points) do
        sum_x = sum_x + point.x
        sum_y = sum_y + point.y
        sum_z = sum_z + (point.z or 0)
        count = count + 1
    end
    
    if count > 0 then
        return sum_x / count, sum_y / count, sum_z / count
    else
        return 0, 0, 0
    end
end

-- Calculate the weighted center point of a group of points
---@param points table Array of points, each with x, y, z coordinates and weight
---@return number center_x, number center_y, number center_z The weighted center point coordinates
function MathUtils.weighted_center_point(points)
    if not points or #points == 0 then
        return 0, 0, 0
    end
    
    local sum_x, sum_y, sum_z = 0, 0, 0
    local total_weight = 0
    
    for _, point in ipairs(points) do
        local weight = point.weight or 1
        sum_x = sum_x + point.x * weight
        sum_y = sum_y + point.y * weight
        sum_z = sum_z + (point.z or 0) * weight
        total_weight = total_weight + weight
    end
    
    if total_weight > 0 then
        return sum_x / total_weight, sum_y / total_weight, sum_z / total_weight
    else
        return 0, 0, 0
    end
end

-- Normalize a vector to have a length of 1
---@param x number Vector x component
---@param y number Vector y component
---@param z number Vector z component
---@return number norm_x, number norm_y, number norm_z The normalized vector components
function MathUtils.normalize_vector(x, y, z)
    local length = math.sqrt(x^2 + y^2 + z^2)
    if length > 0 then
        return x / length, y / length, z / length
    else
        return 0, 0, 0
    end
end

-- Calculate the dot product of two vectors
---@param x1 number First vector x component
---@param y1 number First vector y component
---@param z1 number First vector z component
---@param x2 number Second vector x component
---@param y2 number Second vector y component
---@param z2 number Second vector z component
---@return number dot_product The dot product of the vectors
function MathUtils.dot_product(x1, y1, z1, x2, y2, z2)
    return x1 * x2 + y1 * y2 + z1 * z2
end

-- Calculate the cross product of two vectors
---@param x1 number First vector x component
---@param y1 number First vector y component
---@param z1 number First vector z component
---@param x2 number Second vector x component
---@param y2 number Second vector y component
---@param z2 number Second vector z component
---@return number cross_x, number cross_y, number cross_z The cross product vector components
function MathUtils.cross_product(x1, y1, z1, x2, y2, z2)
    local cross_x = y1 * z2 - z1 * y2
    local cross_y = z1 * x2 - x1 * z2
    local cross_z = x1 * y2 - y1 * x2
    return cross_x, cross_y, cross_z
end

-- Linear interpolation between two values
---@param a number First value
---@param b number Second value
---@param t number Interpolation factor (0-1)
---@return number result The interpolated value
function MathUtils.lerp(a, b, t)
    return a + (b - a) * t
end

-- Clamp a value between a minimum and maximum
---@param value number The value to clamp
---@param min number The minimum allowed value
---@param max number The maximum allowed value
---@return number clamped_value The clamped value
function MathUtils.clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

-- Calculate the optimal kiting path
---@param player_x number Player x coordinate
---@param player_y number Player y coordinate
---@param enemies table Array of enemy positions
---@param kite_distance number Distance to kite
---@return number path_x, number path_y The optimal kiting path coordinates
function MathUtils.calculate_kiting_path(player_x, player_y, enemies, kite_distance)
    if not enemies or #enemies == 0 then
        return player_x, player_y
    end
    
    -- Calculate the average direction vector away from enemies
    local dir_x, dir_y = 0, 0
    
    for _, enemy in ipairs(enemies) do
        local enemy_x, enemy_y = enemy.x, enemy.y
        local dx = player_x - enemy_x
        local dy = player_y - enemy_y
        
        -- Normalize the direction vector
        local length = math.sqrt(dx^2 + dy^2)
        if length > 0 then
            dx = dx / length
            dy = dy / length
            
            -- Add to the total direction
            dir_x = dir_x + dx
            dir_y = dir_y + dy
        end
    end
    
    -- Normalize the final direction
    local dir_length = math.sqrt(dir_x^2 + dir_y^2)
    if dir_length > 0 then
        dir_x = dir_x / dir_length
        dir_y = dir_y / dir_length
        
        -- Calculate the kiting path
        local path_x = player_x + dir_x * kite_distance
        local path_y = player_y + dir_y * kite_distance
        
        return path_x, path_y
    end
    
    return player_x, player_y
end

-- Calculate the optimal position to gather enemies
---@param player_x number Player x coordinate
---@param player_y number Player y coordinate
---@param enemies table Array of enemy positions
---@param group_members table Array of group member positions
---@return number gather_x, number gather_y The optimal gathering position coordinates
function MathUtils.calculate_gathering_position(player_x, player_y, enemies, group_members)
    if not enemies or #enemies == 0 or not group_members or #group_members == 0 then
        return player_x, player_y
    end
    
    -- Calculate the center of the group
    local group_points = {}
    for _, member in ipairs(group_members) do
        table.insert(group_points, {x = member.x, y = member.y, z = member.z or 0})
    end
    
    local group_center_x, group_center_y, _ = MathUtils.center_point(group_points)
    
    -- Calculate the center of the enemies
    local enemy_points = {}
    for _, enemy in ipairs(enemies) do
        table.insert(enemy_points, {x = enemy.x, y = enemy.y, z = enemy.z or 0})
    end
    
    local enemy_center_x, enemy_center_y, _ = MathUtils.center_point(enemy_points)
    
    -- Calculate a position between the group and enemies, but closer to the group
    local gather_x = group_center_x * 0.7 + enemy_center_x * 0.3
    local gather_y = group_center_y * 0.7 + enemy_center_y * 0.3
    
    return gather_x, gather_y
end

return MathUtils 