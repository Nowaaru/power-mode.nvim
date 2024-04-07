-- use the NeoVim buffer like a canvas
local PowerInstruction = require("power-mode.power-instruction");
--- @class PowerLayerConstructor
-- The constructor for the PowerLayer class.
local PowerLayer       = {};

---@class PowerLayerPrototype
---@field name string The name of the layer.
---@field __ns number The namespace the layer belongs to.
---@field __win PowerWindow The window the layer belongs to.
---@field __ext number The number of the mark the layer possesses.
---@field __instructions table<string | number, PowerInstruction> The instructions the layer possesses.
PowerLayer.__prototype = {
    name = "Prototype",
    __buf = nil,
    __win = nil,
    __ns = nil,
    __ext = nil,
    __instructions = {
        _bg = PowerInstruction.new(function()

        end)
    },
};

---The window to apply this fill to.
---@param color? string The color of the fill.
function PowerLayer.__prototype:Fill(color)
    assert(self.__win, "layer must be bound to a window for this command to work.");
    self.__instructions._bg:Update(function()
        vim.api.nvim_set_hl(self.__ns, self:MakeLayerId(), { bg = color, fg = color })
        self.__ext = vim.api.nvim_buf_set_extmark(self.__buf, self.__ns, 0, 0, {
            -- ephemeral = true,
            end_row = self.__win.Height,
            hl_eol = true,
            hl_group = self:MakeLayerId(),
        })
    end)
end

function PowerLayer.__prototype:MakeLayerId()
    return "power-mode-layer-" .. self.name;
end

function PowerLayer.__prototype:Clear()
    self.__instructions.bg:Update(function()
        vim.api.nvim_buf_del_extmark(self.__buf, self.__ns, self.__ext);
        self.__ext = nil;
    end);
end

function PowerLayer.__prototype:Execute()
    if self.__instructions._bg then
        self.__instructions._bg:Execute()
    end

    ---@type table<integer, PowerInstruction>
    local inst = {};

    for i, v in pairs(self.__instructions) do
        if (type(i) == "number") then inst[i] = v end;
    end

    for _, v in ipairs(inst) do
        v:Execute()
    end
end

---Bind this layer to a window.
---@param win PowerWindow
function PowerLayer.__prototype:BindWindow(win)
    self.__win = win;
    self.__buf = win.__buf;
end

--- Make a new PowerLayer.
---@param name string The name of the PowerLayer.
---@param namespace integer The name of the PowerLayer's namespace.
---@return PowerLayer layer The new PowerLayer.
---@nodiscard
function PowerLayer.new(name, namespace, buffer)
    ---@class PowerLayer : PowerLayerPrototype, Proxy
    return setmetatable({
        name = name,
        __ns = namespace,
        __win = nil,
        __buf = buffer,
        __ext = nil,
        __instructions = {
            _bg = PowerInstruction.new(function()

            end)
        },
    }, PowerLayer.__prototype);
end

PowerLayer.__prototype.__index = PowerLayer.__prototype;
PowerLayer.__prototype = PowerLayer.__prototype;

return PowerLayer;
