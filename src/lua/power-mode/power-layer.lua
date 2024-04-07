---@enum (key) SpecialInstruction
local SpecialInstruction = {
    BACKGROUND = "bg",
};

-- Use the NeoVim buffers like a canvas.
local PowerInstruction   = require("power-mode.power-instruction");
--- @class PowerLayerConstructor
-- The constructor for the PowerLayer class.
local PowerLayer         = {};

---@class PowerLayerPrototype
---@field name string The name of the layer.
---@field __ns number The namespace the layer belongs to.
---@field __win PowerWindow The window the layer belongs to.
---@field __ext number The number of the mark the layer possesses.
---@field __instructions { [integer]: PowerInstruction, __special: ({id: string, instruction: PowerInstruction?})[] } The instructions the layer possesses.
PowerLayer.__prototype   = {
    name = "Prototype",
    __buf = nil,
    __win = nil,
    __ns = nil,
    __ext = nil,
    __instructions = {
        -- array of [instructionId, instruction]
        __special = {},
    },
};

---Add an Instruction to the current PowerLayer.
---@param instruction PowerInstruction The Instruction to add to the layer.
function PowerLayer.__prototype:AddInstruction(instruction)
    table.insert(self.__instructions, instruction);
end

--
---Add a Special Instruction to the current PowerLayer.
---@param instructionId SpecialInstruction | string The Id of the special Instruction to add to the layer.
---@param instruction PowerInstruction The Instruction to add to the layer.
function PowerLayer.__prototype:SetSpecialInstruction(instructionId, instruction)
    for _, v in pairs(self.__instructions.__special) do
        if (v.id == instructionId) then
            v.instruction = instruction;
            return;
        end
    end

    table.insert(self.__instructions.__special, { id = instructionId, instruction = instruction });
end

---Fill the window with a color.
---@param color? string The color of the fill.
function PowerLayer.__prototype:Fill(color)
    assert(self.__win, "layer must be bound to a window for this command to work.");
    self:AddInstruction(PowerInstruction.new(function(instructionId, order)
        local id = self:MakeLayerId(instructionId, color);
        vim.api.nvim_set_hl(self.__ns, id, { fg = color });
        self.__ext = vim.api.nvim_buf_set_extmark(self.__buf, self.__ns, 0, 0, {
            end_row = self.__win.Height,
            hl_eol = true,
            hl_group = id,
            priority = order,
        })
    end, "Fill"));
end

--TODO: maybe have a neat functionality
--that allows me to set Background or call it
--as a method

---Fill the window with a color.
---@param color? string The color of the fill.
function PowerLayer.__prototype:Background(color)
    assert(self.__win, "layer must be bound to a window for this command to work.");
    self:SetSpecialInstruction(SpecialInstruction.BACKGROUND, PowerInstruction.new(function(instructionId, order)
        local id = self:MakeLayerId(instructionId, color);
        vim.api.nvim_set_hl(self.__ns, id, { bg = color, fg = color })
        self.__ext = vim.api.nvim_buf_set_extmark(self.__buf, self.__ns, 0, 0, {
            end_row = self.__win.Height,
            hl_eol = true,
            hl_group = id,
                priority = order;
        })
    end, SpecialInstruction.BACKGROUND));
end

---Fill a bar with a color.
---@param color? string The color of the bar.
function PowerLayer.__prototype:Bar(line, percentage, color)
    percentage = percentage or 1;
    percentage = (percentage > 1) and (percentage / 100) or percentage;
    assert(self.__win, "layer must be bound to a window for this command to work.");

    table.insert(self.__instructions, PowerInstruction.new(
        function(instructionId, order)
            local id = self:MakeLayerId(instructionId, color);
            vim.api.nvim_set_hl(self.__ns, id, { bg = color, fg = color })
            self.__ext = vim.api.nvim_buf_set_extmark(self.__buf, self.__ns, line, 0, {
                end_row = line,
                end_col = math.min(self.__win.Width * percentage, self.__win.Width),
                hl_group = id,
                priority = order;
            })
        end, "Bar"))
end

---comment
---@param hl_name string The name of the highlight to get.
function PowerLayer.__prototype:GetHighlight(hl_name)
end

function PowerLayer.__prototype:MakeLayerId(instructionId, color)
    local out = "power-mode-layer-" ..
        self.name .. (instructionId and ("-" .. instructionId) or "") .. (color and ("-" .. color:gsub("#", "")) or "")

    return out, vim.api.nvim_get_hl_id_by_name(out);
end

function PowerLayer.__prototype:Clear()
    self:SetSpecialInstruction(SpecialInstruction.BACKGROUND,
        PowerInstruction.new(function()
            vim.api.nvim_buf_del_extmark(self.__buf, self.__ns, self.__ext);
            self.__ext = nil;
        end, "Clear"));
end

function PowerLayer.__prototype:Execute()
    ---@type table<integer, PowerInstruction>
    local inst = {};

    -- using ipairs here allows us to store
    -- links for special instructions,
    -- notably, something like a background
    -- fill
    for _, v in ipairs(self.__instructions.__special) do
        if (not v.instruction) then
            goto continue
        end


        table.insert(inst, v.instruction);
        ::continue::
    end

    for _, v in ipairs(self.__instructions) do
        table.insert(inst, v)
    end

    for order, v in ipairs(inst) do
        v:Execute(order)
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
        __instructions = { __special = {} },
    }, PowerLayer.__prototype);
end

PowerLayer.__prototype.__index = PowerLayer.__prototype;
PowerLayer.__prototype = PowerLayer.__prototype;

return PowerLayer;
