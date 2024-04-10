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

    ---@type table<string, table>
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
    local timerIntervalMs = (1 / 60) * 1000;
    local scoreDecreaseCount = 2;
    local scoreIncrease = 3;
    local scoreCap = 10;
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

    -- TODO: Implement a "flow" multiplier where as long
    -- as the user makes consistent changes then a
    -- multiplier is applied to the added score.
    self.scoreIncreaseTimer = vim.loop.new_timer();
    self.scoreIncreaseTimer:start(0, (timerIntervalMs < 1) and timerIntervalMs * 1000 or timerIntervalMs, function()
        for buf, scoreItem in pairs(self.test_buffer_store) do
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
                local lengthDelta = (scoreItem.length_prev - scoreItem.length);
                local lengthDeltaAbs = math.abs(lengthDelta)
                scoreItem.time = scoreItem.time + timerIntervalMs;
                scoreItem.score = scoreItem.score +
                    math.max(0, math.min(scoreCap,
                        (scoreIncrease * lengthDeltaAbs) / (timerIntervalMs * 0.5)));

                if (scoreItem.state_decrease >= scoreDecreaseCount) then
                    scoreItem.state_decrease = 0;
                    scoreItem.score = math.max(scoreItem.score - math.abs((3 * scoreIncrease) / timerIntervalMs), 0);
                    vim.schedule(function()
                        bar:Clear();
                        bar:Bar(0, scoreItem.score / scoreCap, "#FFFFFF" --[[  "#CF3369" ]]);
                        updateWindow(win, { background, bar });
                    end)
                else
                    scoreItem.state_decrease = scoreItem.state_decrease + 1
                end;
            end
            ::update_length::
            scoreItem.length_prev = scoreItem.length;
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
    local match, buf, file, data = args.match, args.buf, args.file, args.data;
    local bufferOffset = 2; -- unsure why but the buffer length is always increased by 2 :thonk:
    local bufferLength = math.max(0, vim.fn.line2byte(vim.fn.line("$") + 1) - bufferOffset);

    local storeItem = self:store_item_or(args.buf);
    storeItem.length = bufferLength;
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
    return {
        length_prev = 0,
        length = 0,

        score = 0,
        time = 0,
        state_decrease = 0,
    };
end

-- function module:display_virtual_text()
--     local bnr = vim.api.nvim_get_current_buf(); --vim.fn.bufnr("%r");
--     local ns_id = vim.api.nvim_create_namespace('power-mode');
--     print("ns id:", ns_id);
--
--     local line_num = 5;
--     local col_num = 5;
--
--     local opts = store_item_r
--         end_line = 10,
--         id = 1,
--         virt_text = { { "demo", "IncSearch" } },
--         virt_text_pos = "right_align",
--     };
--
--     local mark_id = vim.api.nvim_buf_set_extmark(bnr, ns_id, line_num, col_num, opts);
--     return mark_id, ns_id;
-- end

function module:__test(imageNvim)
    local Particle = require("power-mode.particle").WithImages(imageNvim);

    local newParticle = Particle.new(nil, nil, 16, "df2935-16x16.png");
    newParticle.X = 25;
    newParticle.Y = 72;
    newParticle.Rendered = true;
end

return module;
