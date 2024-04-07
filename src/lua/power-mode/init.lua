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


    vim.api.nvim_create_autocmd("TextChangedI", {
        group = powerModeGroup,
        callback = function(args)
            self:on_buffer_text_changed(args);
        end
    });


    --[[
    --TODO: make proper scoring system
    --zzz :snore:
    --]]

    self.test_buffer_store = {};
    local timerIntervalMs = 100;
    local scoreDecreaseCount = 2;
    local scoreIncrease = 3;
    local scoreCap = 50;
    local ns_id = vim.api.nvim_create_namespace('power-mode');
    local win = PowerWindow.new();
    win:BindToNamespace(ns_id);

    local layer = PowerLayer.new("Ligma", ns_id, win.__buf);
    layer:BindWindow(win);
    layer:Fill("#DF2935");

    win:AddLayer(layer);
    print("showing window");
    win:Show();

    self.scoreIncreaseTimer = vim.loop.new_timer();
    self.scoreIncreaseTimer:start(0, timerIntervalMs, function()
        for _, scoreItem in pairs(self.test_buffer_store) do
            scoreItem.time = scoreItem.time + timerIntervalMs;
            scoreItem.score = scoreItem.score +
                math.min(scoreCap,
                    scoreIncrease * math.abs(scoreItem.length_prev - scoreItem.length) / (timerIntervalMs * 0.5));

            if (scoreItem.state_decrease >= scoreDecreaseCount) then
                scoreItem.state_decrease = 0;
                scoreItem.score = math.max(scoreItem.score - ((3 * scoreIncrease) / timerIntervalMs), 0);
            else
                scoreItem.state_decrease = scoreItem.state_decrease + 1
            end;

            -- print(("score for bufid %s: %s"):format(bufferId, scoreItem.score));
            scoreItem.length_prev = scoreItem.length;
        end
    end)

    -- window moving and working the renderer
    vim.api.nvim_create_autocmd("CursorMoved", {
        group = powerModeGroup,
        callback = function(_)
            local cursor_pos = vim.api.nvim_win_get_cursor(0);
            win.X, win.Y = unpack(cursor_pos);
            win:RenderWindow();
        end
    });

    self.decorationProvider = vim.api.nvim_set_decoration_provider(ns_id, {

        on_end = function()
            win:RenderComponents();
        end,

    });
end

function module:on_buffer_text_changed(args)
    -- local match, buf, file, data = args.match, args.buf, args.file, args.data;
    -- local bufferOffset = 2; -- unsure why but the buffer length is always increased by 2 :thonk:
    -- local bufferLength = math.max(0, vim.fn.line2byte(vim.fn.line("$") + 1) - bufferOffset);

    -- print("buffer length:", bufferLength);
    local bufferId = tostring(args.buf);
    local storeItem = self.test_buffer_store[bufferId];
    if (not storeItem) then
        storeItem = self:test_make_default_storeitem();
        self.test_buffer_store[bufferId] = storeItem;
    end
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
--     local opts = {
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
