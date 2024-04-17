--[[
-- TODO: make a particle pool to reuse particles
-- so i don't explode my computer by accident
--]]

-- TODO:
-- give the module a 'preset' field
-- that automatically runs and processes
-- preset instances

---@class PowerMode The Power Mode class.
---@field protected __namespace integer The default namespace for this instance.
local module      = {
    __namespace = vim.api.nvim_create_namespace('power-mode'),
    __group_name = "power-mode.nvim/handler",
};

local unpack      = table.unpack or unpack;
local PowerWindow = require("power-mode.power-window")
local PowerLayer  = require("power-mode.power-layer")
local Scorekeep   = require("power-mode.scorekeep")
local util        = require("power-mode.util")
local AnchorType  = require("power-mode.power-window.anchortype")

function module:assert(a, msg)
    if (not a) then
        error(msg);
    end

    return true;
end

function module:__getLogStr(...)
    return ("power-mode.nvim/init: " .. table.concat({ ... }, " "));
end

function module:log(...)
    print(self:__getLogStr(...));
end

function module.Setup()
    return module:setup(); -- error wouldn't shut up :/
end

function module:setup()
    local supportsImages, imageNvim = pcall(function()
        return require("image");
    end);

    print(supportsImages, imageNvim);

    self:assert(supportsImages, "unable to locate plugin '3rd/image.nvim.'");
    print("3rd/image.nvim successfully found.");

    -- TODO: Implement score decay type option
    -- (stamina, rapid-decay, no-decay)

    -- TODO: Add some kind of consistency indicator bar
    -- self.scoreIncreaseTimer = vim.loop.new_timer();

    return Scorekeep;
end

function module:__test_preset()
    local a = vim.fn.getcwd() .. "/" .. vim.api.nvim_buf_get_name(0);
    if not a:match("test") then
        return print("ok")
    end

    local Preset = require("power-mode.presets.boss");
    local Boss = Preset.new(module.__group_name);


    vim.api.nvim_create_autocmd("VimResized", {
        callback = function(buf)
            if (buf ~= vim.api.nvim_get_current_buf()) then
                return;
            end

            Boss:UpdateWindow();
        end

    });

    Boss:on_init(self.__namespace);
    self.decorationProvider = vim.api.nvim_set_decoration_provider(module.__namespace, {
        on_start = function(_, tick)
            return Boss:on_start()
        end
    })
end

function module:__test(imageNvim)
    local Particle = require("power-mode.particle").WithImages(imageNvim);
    local newParticle = Particle.new(nil, nil, 16, "df2935-16x16.png");
    newParticle.X = 25;
    newParticle.Y = 72;
    newParticle.Rendered = true;
end

return module;
