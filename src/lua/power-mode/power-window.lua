local PowerWindow = {};
local Proxy = require("power-mode.proxy");
PowerWindow.__prototype = {
    X = 0,
    Y = 0,
    Width = 100,
    Height = 100,
    Background = 0x000000,
    __buf = vim.api.nvim_create_buf(false, true),
    __win = nil,
    __showing = false,
};

function PowerWindow.__prototype:Show()
    self.__showing = true;
end

function PowerWindow.__prototype:Hide()
    self.__showing = false;
end

function PowerWindow.new()
    return Proxy(setmetatable({
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
                self.__win = vim.api.nvim_open_win(self.__buf, false, {
                    focusable = false,
                    bufpos = { self.X, self.Y },
                    width = 12,
                    height = 3,
                    win = 0,
                    style = "minimal",
                    relative = "cursor",
                });
            end
        end
    }, PowerWindow.__prototype));
end
