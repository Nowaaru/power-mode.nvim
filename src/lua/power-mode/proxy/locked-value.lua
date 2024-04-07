local Proxy = require("power-mode.proxy")


---@class LockedValueConstructor
local LockedValue = {
    __prototype = {},
};

---@return LockedValue The locked value.
function LockedValue.new(...)
    ---@class LockedValue : Proxy
    local obj = Proxy { }
end

