-- @name text.lua
-- @rev 2024/03/26
-- @by Nowaaru
-- @license gpl3.0
--
-- @desc
-- A basic text example for proxy.lua.
-- Field change events included.

local Proxy = require("power-mode.proxy");

---@class (exact) TextConstructor
---@overload fun(self: TextConstructor, text?: string): Text
local TextConstructor = setmetatable({
    ---@param text? string The text to display.
    ---@return Text text The newly-constructed Text object.
    new = function(text)
        ---@class Text : Proxy
        ---@field Font string The name of the font.
        ---@field FontSize number The size of the font.
        local Text = Proxy {
            __readyToRender = false,

            Text = text ~= nil and tostring(text) or "",
            Font = "Times New Roman",
            FontSize = 12,
            Render = function(self)
                self.__readyToRender = true;
            end
        };

        local keysOf = function(this)
            local out = {};
            for k, _ in pairs(this) do
                out[k] = k;
            end

            return out;
        end

        for k, _ in pairs(keysOf(Text)) do
            ---@private
            Text[("__%sChanged"):format(k)] = function(self, previous, new)
                print(("variable 'Text.%s' was changed. [(%s) -> (%s)]"):format(k, previous, new))
            end
        end

        return Text;
    end

}, {
    __call = function(self, ...)
        return self.new(...)
    end,
});

return TextConstructor;
