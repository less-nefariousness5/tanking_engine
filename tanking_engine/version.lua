-- Central version management for Tanking Engine
-- This file serves as the single source of truth for version information

local version = {
    major = 0,
    minor = 1,
    patch = 0,

    -- Generate string version for display
    toString = function(self)
        return string.format("%d.%d.%d", self.major, self.minor, self.patch)
    end,

    -- Bump version based on commit type
    bump = function(self, type)
        if type == "feat" then
            self.minor = self.minor + 1
            self.patch = 0
        elseif type == "fix" or type == "perf" or type == "refactor" then
            self.patch = self.patch + 1
        end
        return self:toString()
    end,

    -- Check if current version is newer than input version
    isNewerThan = function(self, version_string)
        local other_major, other_minor, other_patch = string.match(version_string, "(%d+)%.(%d+)%.(%d+)")
        other_major = tonumber(other_major) or 0
        other_minor = tonumber(other_minor) or 0
        other_patch = tonumber(other_patch) or 0
        
        if self.major > other_major then
            return true
        elseif self.major == other_major and self.minor > other_minor then
            return true
        elseif self.major == other_major and self.minor == other_minor and self.patch > other_patch then
            return true
        end
        return false
    end
}

return version
