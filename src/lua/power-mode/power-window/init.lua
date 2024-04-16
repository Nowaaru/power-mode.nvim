local PowerWindow = {};
local AnchorType = require("power-mode.power-window.anchortype");
local AnchorPosition = require("power-mode.power-window.anchorposition")
local Proxy = require("power-mode.proxy");
local Util = require("power-mode.util");
local BorderType = require("power-mode.power-window.bordertype")
---@class PowerWindowPrototype
---@field __layers PowerLayer[] All layers to be written to this PowerWindow.
---@field __win integer The ID of the PowerWindow.
---@field __buf integer The ID of the buffer of the PowerWindow.
---@field __ns integer The namespace that the PowerWindow will belong to.
--
---@field X integer The X position of the window.
---@field Y integer The Y position of the window.
---@field Width integer The width of the window.
---@field Height integer The height of the window.
PowerWindow.__prototype = {
    X = 0,
    Y = 0,
    Width = 10,
    Height = 2,
    Background = 0x000000,
    __buf = nil,
    __win = nil,
    __ns = nil,
    __showing = false,
    __layers = {},
    RenderOptions = {};
};

function PowerWindow.__prototype:Show()
    self.__showing = true;
end

function PowerWindow.__prototype:Hide()
    self.__showing = false;
end

function PowerWindow.__prototype:AddLayer(...)
    for _, v in pairs({ ... }) do
        for _, w in pairs(self.__layers) do
            if (v == w) then
                goto continue;
            end
        end
        table.insert(self.__layers, v);
        v:BindWindow(self --[[ @as PowerWindow ]])
        ::continue::
    end
end

function PowerWindow.__prototype:ClearLayers()
    self.__layers = {};
end

---Binds this window to the given namespace id.
---@param namespace_id integer The ID of the namespace to bind the window to.
function PowerWindow.__prototype:BindToNamespace(namespace_id)
    assert(Util:NamespaceExists(namespace_id), ("Namespace %s does not exist."):format(namespace_id))
    self.__ns = namespace_id;
end
--
function PowerWindow.__prototype:GenerateRenderOptions(overrides)
    if (self.Width == PowerWindow.__prototype.Width) then
        print("width:", self.Width);
        -- print("self:", vim.inspect(self))
    end
    local out = {
        focusable = false,
        col = self.X,
        row = self.Y,
        width = self.Width,
        height = self.Height,
        style = "minimal",
        relative = AnchorType.ABSOLUTE,
        anchor = AnchorPosition.SOUTHWEST,
        border = BorderType.ROUNDED,
        zindex = 25,
    }

    for i, v in pairs(overrides or self.RenderOptions) do
        out[i] = v;
    end

    return out;
end

function PowerWindow.__prototype:SetRenderOptions(overrides)
    self.RenderOptions = overrides;
end

function PowerWindow.__prototype:SetRenderOption(option, value)
    self.RenderOptions[option] = value;
end


---@param borderType BorderType The type of border the window will have.
function PowerWindow.__prototype:ChangeBorder(borderType)
    self.RenderOptions.border = borderType;
end


---@param anchorPoint AnchorPosition The corner that will be used to position the window.
function PowerWindow.__prototype:SetAnchorPoint(anchorPoint)
    self.RenderOptions.anchor = anchorPoint;
end
--
---@param anchorType AnchorType The corner that will be used to position the window.
function PowerWindow.__prototype:SetAnchorType(anchorType)
    self.RenderOptions.relative = anchorType;
end

function PowerWindow.__prototype:RenderComponents()
    if (self.__showing) then
        -- print("oh yea im showing", self.X, self.Y, vim.inspect(self));
        if (not self.__win) then
            return print("would render but __win is nil", os.clock());
        end
        for _, v in pairs(self.__layers or {}) do
            v:Execute();
        end

        vim.api.nvim_win_set_hl_ns(self.__win, self.__ns)
        --[[ else print ("oh nah. showing was false") ]]
    elseif (not self.__showing and vim.fn.winbufnr(self.__buf) ~= -1) then
        if (self.__win) then
            vim.api.nvim_win_close(self.__win, true)
        end
    end

    self:ClearLayers();
end

local function ConvertLinesToHashes(lines, length)
    local lines_as_hashes = {};
    local line_dummy = " " -- "#"
    for _ = 0, lines do
        table.insert(lines_as_hashes, (line_dummy):rep(length));
    end

    return lines_as_hashes;
end

function PowerWindow.__prototype:RenderWindow()
    if (self.__win) then
        vim.api.nvim_win_set_config(self.__win, PowerWindow.__prototype.GenerateRenderOptions(self));
    end

    if (self.__showing) then
        if (not self.__win) then
            self.__win = vim.api.nvim_open_win(self.__buf, false, PowerWindow.__prototype.GenerateRenderOptions(self));
        end
        -- self:Update(ConvertLinesToHashes(self.Height, self.Width));
    elseif (vim.fn.winbufnr(self.__buf) ~= -1) then
        if (self.__win) then
            vim.api.nvim_win_hide(self.__win)
        end
    end

    if (self.__win) then
        vim.api.nvim_win_set_cursor(self.__win, {1,0})
    end
end

---Update the buffer with the provided lines.
---
---⚠ WARNING: Will clear all external marks.
---
---@param lines any
---@return nil
function PowerWindow.__prototype:Update(lines)
    return vim.api.nvim_buf_set_text(self.__buf, 0, 0, self.Height, self.Width, lines or { "default text." });
end

---@class PowerWindowConstructor
---@param name string? The name of the Window.
---@return PowerWindow The new PowerWindow.
function PowerWindow.new(name)
    ---@class Object : PowerWindowPrototype
    local obj = {
        __buf = vim.api.nvim_create_buf(false, true),
    };

    function obj:____showingChanged(from, to)
        if (to) then
            self:RenderWindow();
        elseif (not from) then
            print("hiding window");
            vim.api.nvim_win_close(self.__win, true);
        end
    end

    local function updLines(self, size)
        PowerWindow.__prototype.RenderWindow(self);
        vim.api.nvim_buf_set_lines(self.__buf, 0, 0, false, ConvertLinesToHashes(size.Height, size.Width));
    end

    function obj:__WidthChanged(old, new)
        print(("width changed yeye (%s -> %s)"):format(old, new));
        if (self.__win) then
            vim.api.nvim_win_set_width(self.__win, new or self.Width);
        end

        updLines(self, {Height = self.Height, Width = new})
    end

    function obj:__HeightChanged(old, new)
        print(("height changed yeye (%s -> %s)"):format(old, new));
        if (self.__win) then
            vim.api.nvim_win_set_height(self.__win, new or self.Height);
        end

        updLines(self, {Height = new, Width = self.Width})
    end

    -- function obj:__XChanged(old, new)
    --     -- print(("x changed yeye (%s -> %s)"):format(old, new));
    -- end
    --
    -- function obj:__YChanged(old, new)
    --     -- print(("y changed yeye (%s -> %s)"):format(old, new));
    -- end

    local args = {
        Width = PowerWindow.__prototype.Width,
        Height = PowerWindow.__prototype.Height,
        __buf = obj.__buf
    }

    obj.name = name or ("PowerWindow (%s)"):format(tostring(obj):sub(8));
    obj.__WidthChanged(args, nil, args.Width);
    obj.__HeightChanged(args, nil, args.Height);


    ---@class PowerWindow : PowerWindowPrototype, Proxy
    return Proxy(setmetatable(obj, PowerWindow.__prototype));
end

PowerWindow.__prototype.__index = PowerWindow.__prototype;
return PowerWindow;
