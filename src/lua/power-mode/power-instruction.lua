local Proxy = require("power-mode.proxy");
---@class PowerInstructionConstructor
local PowerInstruction = {
};

---@class PowerInstructionPrototype
PowerInstruction.__prototype = {
    _name = nil,
    _func = nil,
    __newindex = function()
        error("This table is locked.")
    end,
    __tostring = function(self)

        return ("PowerInstruction [%s]"):format(tostring(self._func):sub(10));
    end,
    _VERBOSE = false
};

---@return PowerInstruction PowerInstruction The new PowerInstruction object.
function PowerInstruction.new(func, name)
    local obj = {
        _name = name,
        _func = func,
    };

    obj._name = obj._name or PowerInstruction.__prototype.__tostring(obj);

    ---@class PowerInstruction : PowerInstructionPrototype, Proxy
    return Proxy(setmetatable(obj, PowerInstruction.__prototype))
end

---Execute the instruction on this layer.
function PowerInstruction.__prototype:Execute()
    if (self._VERBOSE) then
        print(("executing instruction %s"):format(tostring(self)))
    end

    self._func();
end

---Update the PowerInstruction with the new functionality.
---@param func function
function PowerInstruction.__prototype:Update(func)
    self._func = func;
end

PowerInstruction.__prototype.__index = PowerInstruction.__prototype;
return PowerInstruction;
