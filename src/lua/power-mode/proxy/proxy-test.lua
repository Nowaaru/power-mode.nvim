-- @name proxy-test.lua
-- @rev 2024/03/26
-- @by Nowaaru
-- @license gpl3.0
--
-- @desc
-- Shows off the usage of the proxy
-- example.

local Text = require("power-mode.proxy.text");
local test_text = Text.new();

--[[

>> test_text.Font = "Comic Sans MS";
variable 'Text.Font' was changed. [(Times New Roman) -> (Comic Sans MS)]

>> test_text.FontSize = 16;
variable 'Text.FontSize' was changed. [(12) -> (16)]
--]]
--
test_text.Font = "Comic Sans MS";
test_text.FontSize = 16;
