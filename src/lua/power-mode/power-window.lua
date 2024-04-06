local PowerWindow = {};
local Proxy = require("power-mode.proxy");
PowerWindow.__prototype = {
    X = 0,
    Y = 0,
    Width = 100,
    Height = 100,
    Background = 0x000000,
    __win = nil,
    __showing = false,
};


function PowerWindow.__prototype:Show()
    self.__showing = true;
end

function PowerWindow.__prototype:Hide()
    self.__showing = false;
end

function PowerWindow.__prototype:Render()
    if (self.__showing) then
        print("oh yea im showing", self.X, self.Y, vim.inspect(self));
        if (self.__win) then
            vim.api.nvim_win_close(self.__win, true);
            self.__win = nil;
        end

        self.__win = vim.api.nvim_open_win(self.__buf, false, {
            focusable = false,
            col = self.X,
            row = self.Y,
            width = 12,
            height = 3,
            -- win = 0,
            style = "minimal",
            relative = "cursor",
            anchor = "SW",
            noautocmd = true,
            zindex = 25,
        });
    --[[ else print ("oh nah. showing was false") ]] end
end

function PowerWindow.__prototype:Update(lines)
    -- print(vim.inspect(self));
    -- print (self == PowerWindow.__prototype, self.X, self.Y)
    -- return vim.api.nvim_buf_set_lines(self.__buf, 0, 0, false, lines or { "default text." });
end

PowerWindow.__prototype.__index = PowerWindow.__prototype;

function PowerWindow.new()
    return Proxy(setmetatable({
        name = "lol",
        __buf = vim.api.nvim_create_buf(false, true),
        __WidthChanged = function(self, from, to)
            print("width changed:", from, to);
        end,
        __HeightChanged = function(self, from, to)
            print("height changed:", from, to);
        end,
        __BackgroundChanged = function(self, from, to)
        end,
        ____showingChanged = function(self, from, to)
            if (to) then
                -- local cursor_pos = vim.api.nvim_win_get_cursor(0);
                print("oh yeah we showing now");
                print(( "to (%s):" ):format(self.name), to)
                self:Render();
            elseif (not from) then
                vim.api.nvim_win_close(self.__win, true)
            end
        end
    }, PowerWindow.__prototype));
end

return PowerWindow;
