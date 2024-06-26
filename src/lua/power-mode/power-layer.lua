local util               = require "power-mode.util"
--TODO: make special animation_state key in layer
--to keep track of fade animations and tweens

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
---@field __exts number[] The mark numbers the layer possesses.
---@field __instructions { [integer]: PowerInstruction, __special: ({id: string, instruction: PowerInstruction?})[] } The instructions the layer possesses.
PowerLayer.__prototype   = {
    name = "Prototype",
    __buf = nil,
    __win = nil,
    __ns = nil,
    __exts = nil,
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
        vim.api.nvim_set_hl(self.__ns, id, { bg = color, fg = color });
        table.insert(self.__exts, vim.api.nvim_buf_set_extmark(self.__buf, self.__ns, 0, 0, {
            end_row = self.__win.Height,
            hl_eol = true,
            hl_group = id,
            priority = order,
        }))
    end, "Fill"));
end

--TODO: maybe have a neat functionality
--that allows me to set Background or call it
--as a method

---Fill the window with a color.
---@param color? string The color of the fill.
function PowerLayer.__prototype:Background(color)
    -- TODO: look into using links to cut down on the sheer amount of highlights being made
    assert(self.__win, "layer must be bound to a window for this command to work.");
    self:SetSpecialInstruction(SpecialInstruction.BACKGROUND, PowerInstruction.new(function(instructionId, order)
        local id = self:MakeLayerId(instructionId, color);
        vim.api.nvim_set_hl(self.__ns, id, { bg = color, fg = color })

        table.insert(self.__exts,  vim.api.nvim_buf_set_extmark(self.__buf, self.__ns, 0, 0, {
            end_row = self.__win.Height,
            hl_eol = true,
            hl_group = id,
            priority = order,
        }))
    end, SpecialInstruction.BACKGROUND));
end

---@param x integer The X position of the text.
---@param y integer The Y position of the text.
---@param foreground? string The color of the text.
---@param text string | string[] The text to write.
function PowerLayer.__prototype:Text(x, y, background, foreground, text)
    assert(self.__win, "layer must be bound to a window for this command to work.");
    self:AddInstruction(PowerInstruction.new(function(instructionId, order)
        local id = self:MakeLayerId(instructionId, foreground);
        vim.api.nvim_set_hl(self.__ns, id, { bg = background, fg = foreground });
        local t = util:Split(text, "\n")
        for i, v in pairs(t) do
            t[i] = { v, id };
        end

        table.insert(self.__exts, vim.api.nvim_buf_set_extmark(self.__buf, self.__ns, y, x, {
            end_col = self.__win.Width,
            hl_eol = true,
            hl_group = id,
            virt_text = type(text) == "table" and text or t,
            virt_text_pos = "overlay",
            priority = order,
        }))
    end, "Text"));
end

---Fill a bar with a color.
---Uses the background highlight.
---@param color? string The color of the bar.
function PowerLayer.__prototype:Bar(start_line, height, percentage, color)
    start_line = math.floor(start_line + 0.5)
    height = math.floor((height or 1) + 0.5)
    color = color or "#000000";
    percentage = tonumber(percentage) or 1;
    percentage = math.max(0, math.min(percentage, 1));
    assert(self.__win, "layer must be bound to a window for this command to work.");

    table.insert(self.__instructions, PowerInstruction.new(
        function(instructionId, order)
            local id = self:MakeLayerId(instructionId, color);
            -- local end_row = math.min(math.floor(line), self.__win.Height);
            local end_col = math.floor(math.min(self.__win.Width * percentage, self.__win.Width --[[ @as integer ]]) + 0.5);
            vim.api.nvim_set_hl(self.__ns, id, { bg = color, fg = color })
            for line = start_line, math.min(height or 1, self.__win.Height --[[ @as integer ]]) do
                table.insert(self.__exts, vim.api.nvim_buf_set_extmark(self.__buf, self.__ns, line, 0, {
                    -- end_row = line,
                    end_col = end_col,
                    hl_group = id,
                    priority = order,
                }))
            end
        end, "Bar"))
end

function PowerLayer.__prototype:MakeLayerId(instructionId, color)
    local out = "power-mode-layer-" ..
        self.name .. (instructionId and ("-" .. instructionId) or "") .. (color and ("-" .. color:gsub("#", "")) or "")

    return out, vim.api.nvim_get_hl_id_by_name(out);
end

function PowerLayer.__prototype:Clear()
    self:Reset();
    self:SetSpecialInstruction(SpecialInstruction.BACKGROUND,
        PowerInstruction.new(function()
            for _, v in pairs(self.__exts) do
                vim.api.nvim_buf_del_extmark(self.__buf, self.__ns, v);
            end
            self.__exts = {};
        end, "Clear"));
end

function PowerLayer.__prototype:Reset()
    -- TODO:
    -- implement a way to keep track of all
    -- created extmarks so i can flush them
    -- when clear is called. preferably just
    -- give them some kinda id to use for
    -- extmarks
    self.__instructions = { __special = {}, };
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
        __exts = {},
        __instructions = { __special = {} },
    }, PowerLayer.__prototype);
end

PowerLayer.__prototype.__index = PowerLayer.__prototype;
PowerLayer.__prototype = PowerLayer.__prototype;

return PowerLayer;
