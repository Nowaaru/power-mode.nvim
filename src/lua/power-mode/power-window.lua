local PowerWindow = {};
local Proxy = require("power-mode.proxy");
local Util = require("power-mode.util");
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
function PowerWindow.__prototype:GenerateRenderOptions()
    return {
        focusable = false,
        col = self.X,
        row = self.Y,
        width = self.Width,
        height = self.Height,
        style = "minimal",
        relative = "cursor",
        anchor = "SW",
        zindex = 25,
    }
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
            vim.api.nvim_win_hide(self.__win)
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
    if (self.__showing) then
        if (self.__win) then
            vim.api.nvim_win_set_config(self.__win, self:GenerateRenderOptions());
        else
            self.__win = vim.api.nvim_open_win(self.__buf, false, self:GenerateRenderOptions());
        end
        -- self:Update(ConvertLinesToHashes(self.Height, self.Width));
    elseif (vim.fn.winbufnr(self.__buf) ~= -1) then
        if (self.__win) then
            vim.api.nvim_win_hide(self.__win)
        end
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
            vim.api.nvim_win_hide(self.__win)
        end
    end

    function obj:__WidthChanged()
        print("width changed yeye");
        return vim.api.nvim_buf_set_lines(self.__buf, 0, 0, false, ConvertLinesToHashes(self.Height, self.Width));
    end

    obj.name = name or ("PowerWindow (%s)"):format(tostring(obj):sub(7));
    obj.__WidthChanged({
        Width = PowerWindow.__prototype.Width,
        Height = PowerWindow.__prototype.Height,
        __buf = obj.__buf
    }); --
    obj.__HeightChanged = obj.__WidthChanged;

    ---@class PowerWindow : PowerWindowPrototype, Proxy
    return Proxy(setmetatable(obj, PowerWindow.__prototype));
end

PowerWindow.__prototype.__index = PowerWindow.__prototype;
return PowerWindow;
