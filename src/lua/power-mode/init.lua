--[[
-- TODO: make a particle pool to reuse particles
-- so i don't explode my computer by accident
--]]

local module      = {};
local unpack      = table.unpack or unpack;
local PowerWindow = require("power-mode.power-window");
local PowerLayer  = require("power-mode.power-layer")

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

    local function updateWindow(win, layers, args)
        local cursor_pos = vim.api.nvim_win_get_cursor(0);
        win.X, win.Y = unpack(cursor_pos);
        if (args) then
            -- print("score:", self:store_item_or(args.buf).score);
        end

        win:AddLayer((unpack or table.unpack)(layers));
        win:RenderWindow();
    end

    ---@type table<string, StoreItem>
    self.test_buffer_store = setmetatable({},
        {
            __index = function(this, k)
                return rawget(this, tostring(k))
            end,
            __newindex = function(this, k, v)
                rawset(this, tostring(k), v);
            end,
            __call = function(this)
                return (this[vim.api.nvim_get_current_buf()] or this:test_make_default_storeitem()).score
            end
        });

    local ns_id = vim.api.nvim_create_namespace('power-mode');
    local win = PowerWindow.new();
    win:BindToNamespace(ns_id);

    local background = PowerLayer.new("Background", ns_id, win.__buf);
    background:BindWindow(win);
    background:Background("#DF2935");

    local bar = PowerLayer.new("Bar", ns_id, win.__buf);
    bar:BindWindow(win);


    win:AddLayer(background);
    print("showing window");
    win:Show();

    -- TODO: Implement score decay type option
    -- (stamina, rapid-decay, no-decay)

    -- TODO: Implement function-based modal multipliers
    -- to allow users to achieve efficiency goals

    -- TODO: Implement a "flow" multiplier where as long
    -- as the user makes consistent changes then a
    -- multiplier is applied to the added score. Length
    -- does of changes does not matter as much to prevent
    -- abuse of other modes.
    --
    -- Non-insert mode changes count as 2.

    -- TODO: Add some kind of consistency indicator bar
    local timerIntervalMs          = (1 / 60) * 1000;
    local scoreDecreaseCount       = 3 * timerIntervalMs;
    local scoreIncrease            = 3;
    local scoreCap                 = 10;

    local timeBeforeComboRemovalMs = 15 * 1000; -- 15 seconds (testing, maybe permanent as a default?)
    local flowMaxMultiplier        = 2.87;

    local euler                    = 2.71828
    local calculateConsistency     = function(amountCharactersTyped, converge)
        converge = converge or flowMaxMultiplier;
        return 1 + math.max(1, math.min(converge, 0.8 * math.log(math.pow(amountCharactersTyped, 0.7), euler)));
    end

    local consistencyDecreaseRate  = 1 / (math.pow(flowMaxMultiplier, 1.3)); -- @ 2.87 ~ 8% loss per tick

    local fixedInterval            = (timerIntervalMs < 1) and timerIntervalMs * 1000 or timerIntervalMs;

    --- WARNING: Modes not specified in this
    --- table will **not** be whitelisted.
    local modalMultipliers         = {
        v = 2.5,
        n = 2,
        i = 1
    };

    self.scoreIncreaseTimer        = vim.loop.new_timer();
    self.scoreIncreaseTimer:start(0, fixedInterval, function()
        for buffer, scoreItem in pairs(self.test_buffer_store) do
            if scoreItem.length_prev == -1 then
                goto update_length;
            end

            --[[
            --do-end required to prevent scope-hopping
            --]]
            do
                --[[
                    doesn't matter what the changes were! just needs
                    to be not nothing
                --]]
                --TODO: move into anywhere else please god
                scoreItem.consistency = calculateConsistency(scoreItem.combo);
                local currentMode = vim.api.nvim_get_mode().mode;
                local isCurrentModeNormal = currentMode == "n";
                local lengthDelta = (scoreItem.length_prev - scoreItem.length);
                local lengthDeltaAbs = math.abs(lengthDelta) * (modalMultipliers[currentMode] or 1)
                local lengthDeltaModalClamped = isCurrentModeNormal and math.log10(lengthDeltaAbs) or lengthDeltaAbs;
                local baseAddedScore = math.max(0, math.min(scoreCap,
                    (scoreIncrease * lengthDeltaModalClamped * scoreItem.consistency) / (timerIntervalMs * 0.5)));


                scoreItem.time = scoreItem.time + timerIntervalMs;
                scoreItem.score = math.min(scoreCap, scoreItem.score + (baseAddedScore));

                if (scoreItem.state_decrease >= scoreDecreaseCount) then
                    -- if (scoreItem.state_decrease % scoreDecreaseCount == 0) then
                    scoreItem.score = math.max(scoreItem.score - math.abs((0.5 * scoreIncrease) / timerIntervalMs), 0)
                    -- end
                end

                if (scoreItem.time > timeBeforeComboRemovalMs) then
                    scoreItem.combo = 0;
                end

                if (scoreItem.length == scoreItem.length_prev) then
                    scoreItem.state_decrease = scoreItem.state_decrease + 1
                    scoreItem.consistency = (scoreItem.consistency - consistencyDecreaseRate)
                else
                    scoreItem.state_decrease = 0;
                end
            end

            ::update_length::
            local score_maintained = scoreItem.score / scoreCap;
            scoreItem.length_prev = scoreItem.length;
            vim.schedule(function()
                if (buffer == tostring(vim.api.nvim_get_current_buf())) then
                    bar:Clear();
                    -- print(scoreItem.score, ":", score_maintained, ("(%i/%s)"):format(score_maintained, scoreCap))
                    bar:Bar(0, 1, score_maintained, "#FFFFFF" --[[  "#CF3369" ]]);
                    updateWindow(win, { background, bar });
                end
            end)
        end
    end)

    -- window moving and working the renderer
    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        group = powerModeGroup,
        callback = function(args)
            updateWindow(win, args)
        end
    });

    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
        group = powerModeGroup,
        callback = function(args)
            self:on_buffer_text_changed(args);
            win:RenderComponents();
        end
    });

    self.decorationProvider = vim.api.nvim_set_decoration_provider(ns_id, {

        on_start = function()
            win:RenderComponents();
        end,

    });
end

function module:on_buffer_text_changed(args)
    local bufferOffset = 2; -- unsure why but the buffer length is always increased by 2 :thonk:
    local bufferLength = math.max(0, vim.fn.line2byte(vim.fn.line("$") + 1) - bufferOffset);

    local storeItem = self:store_item_or(args.buf);
    storeItem.length = bufferLength;
    storeItem.time = 0;           -- time should reset
    storeItem.state_decrease = 0; -- since they typed, resume combo
end

function module:store_item_or(bufferId)
    bufferId = tostring(bufferId);
    local storeItem = self.test_buffer_store[bufferId];
    if (not storeItem) then
        storeItem = self:test_make_default_storeitem();
        self.test_buffer_store[bufferId] = storeItem;
    end

    return storeItem;
end

function module:test_make_default_storeitem()
    ---@class StoreItem
    ---@field length_prev integer The length of the buffer during the last pass.
    ---@field length integer The current length of the buffer.
    ---@field score number The score belonging to this buffer.
    ---@field time integer The remaining time before the combo resets.
    ---@field combo integer How long the user has been consistently typing.
    ---@field consistency number The consistency multiplier derived from the combo.
    ---@field state_decrease integer How many passes have occured without a notable change.
    return {
        length_prev = -1,
        length = 0,

        score = 0,
        time = 0,
        combo = 0,
        consistency = 0,
        state_decrease = 0,
    };
end

function module:__test(imageNvim)
    local Particle = require("power-mode.particle").WithImages(imageNvim);

    local newParticle = Particle.new(nil, nil, 16, "df2935-16x16.png");
    newParticle.X = 25;
    newParticle.Y = 72;
    newParticle.Rendered = true;
end

return module;
