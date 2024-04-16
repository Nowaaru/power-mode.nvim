--[[
-- TODO: make a particle pool to reuse particles
-- so i don't explode my computer by accident
--]]

local module      = {};
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

    local a = vim.fn.getcwd() .. "/" .. vim.api.nvim_buf_get_name(0);
    print("ayy: ", a);
    if not a:match("test") then
        return print("ok")
    end


    local powerModeGroup =
        vim.api.nvim_create_augroup("power-mode.nvim/handler", {
            clear = true,
        });

    --[[
    --TODO: make proper scoring system
    --zzz :snore:
    --]]

    ---@param win PowerWindow
    ---@param layers PowerLayer[]
    local function updateWindow(win, layers, args)
        local Y, X = unpack(vim.api.nvim_win_get_cursor(0));
        -- win.Y, win.X = -1, 0;

        win:AddLayer((unpack or table.unpack)(layers));
        win:RenderWindow();
        win:RenderComponents();
    end

    local screenpos = vim.fn.win_screenpos(0);
    local winwidth = vim.fn.winwidth(0);

    local ns_id = vim.api.nvim_create_namespace('power-mode');
    local win = PowerWindow.new();
    local x = winwidth - win.Width; -- there is no center anchor point, so no /2
    win:SetAnchorType(AnchorType.ABSOLUTE);
    win:BindToNamespace(ns_id);
    win.Width = "50%";
    win.X = (winwidth / 2) - (win.Width / 2)
    win.Y = "100%"
    print("rhs:", x + win.Width, "/", winwidth)

    local background = PowerLayer.new("Background", ns_id, win.__buf);
    background:BindWindow(win);
    background:Background("#DF2935");

    local bar = PowerLayer.new("Bar", ns_id, win.__buf);
    bar:BindWindow(win);

    local text = PowerLayer.new("Text", ns_id, win.__buf);
    text:BindWindow(win);


    win:AddLayer(background);
    print("showing window");
    win:Show();

    -- TODO: Implement score decay type option
    -- (stamina, rapid-decay, no-decay)

    -- TODO: Add some kind of consistency indicator bar
    self.scoreIncreaseTimer = vim.loop.new_timer();

    -- window moving and working the renderer


    local scorekeep = Scorekeep.new(powerModeGroup);
    scorekeep:Start();
    ---@param scoreItem ScoreEntry
    scorekeep.ScoreUpdated = function(scoreItem)
        -- win:RenderComponents()
        -- print(("GRRRR: %s"):format(scoreItem.score))
    end

    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        group = powerModeGroup,
        callback = function(args)
            scorekeep:Ensure(args.buf);
            updateWindow(win, { background, bar }, args)
        end
    });

    self.decorationProvider = vim.api.nvim_set_decoration_provider(ns_id, {

        on_start = function(args)
            local scoreItem = scorekeep:Get()
            if (scoreItem) then
                local score = scoreItem.score / scorekeep.scoreCap
                local fy = tostring(scoreItem.combo) .. "x";
                text:Clear();
                bar:Clear();
                bar:Bar(0, 2, score, "#FFFFFF" --[[  "#CF3369" ]]);
                text:Text(0, 1, nil, "#DF2935", fy)
                win:SetTitle(( "Tim Pope, the Vimdicator (%s%%)" ):format(math.floor(score * 100 + 0.25)));
                win:RenderComponents();
                updateWindow(win, { background, bar, text }, args)
            end
        end,

    });

    return Scorekeep;
end

function module:__test(imageNvim)
    local Particle = require("power-mode.particle").WithImages(imageNvim);
    local newParticle = Particle.new(nil, nil, 16, "df2935-16x16.png");
    newParticle.X = 25;
    newParticle.Y = 72;
    newParticle.Rendered = true;
end

return module;
