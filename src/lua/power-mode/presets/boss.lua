math.randomseed(os.time() + os.clock());

local BossPreset                         = {};
local switch, case, default, fallthrough = unpack(require("power-mode.switch"));
local Scorekeep                          = require("power-mode.scorekeep")
local PowerWindow                        = require("power-mode.power-window")
local PowerLayer                         = require("power-mode.power-layer")
local AnchorType                         = require("power-mode.power-window.anchortype")
local unpack                             = unpack or table.unpack

---@class BossPrototype
---@field bossNames string[]
---@field specialBossNames table<string, string[]>
---@field win PowerWindow The window behind this Preset instance.
BossPreset.__prototype                   = {};
BossPreset.__prototype.bossNames         = {
    "Tim Pope",
    "Nowaaru",
    "Noire",
};

BossPreset.__prototype.rawBossNames      = {};
BossPreset.__prototype.colours           = {
    background = "#DF2935",
    [0] = "#FFFFFF",
};

BossPreset.__prototype.genericBossNames  = {
    "Binger of Hars",
    "The King",
    "The Forsaken",
    "The Exile",
    "Abjudicator of Evil",
    "The Tarnished",
    "Bearer of the Smellden Ring",
    "The Officeworker",
    "The Layman",
    "The Fool",
    "The Tyrant",
    "A Memory of the Past",
};

BossPreset.__prototype.specialBossNames  = {
    Nowaaru = {
        "The Creator",
        "The Arbiter",
        "The Powerful",
        "The Fallen"
    },
    Noire = {
        "Savior of Gamindustri",
        "The Iridiscent",
    },
    ["Tim Pope"] = {
        "The Sensible",
        "The Artist",
        "The Vimdicator",
        "The Commentator",
    },
};


function BossPreset.__prototype:RegenerateBossName()
    local randomName = self.bossNames[math.random(1, #self.bossNames)];
    local bossTitleList = self.specialBossNames[randomName];
    local chosenListQueue;

    -- i can't believe i actually found a
    -- use case for this LOL
    switch(math.random(0, 1)) {
        case(0) {
            function()
                if (bossTitleList) then
                    chosenListQueue = math.random(0, 1) == 0 and bossTitleList or self.genericBossNames;
                end

                local specialTitle = chosenListQueue[math.random(1, #chosenListQueue)];
                self.bossName = randomName .. (specialTitle and (", " .. specialTitle) or "")
            end,
        },

        default {
            function()
                chosenListQueue = self.rawBossNames;
                self.bossName = chosenListQueue[math.random(1, #chosenListQueue)];
            end
        },

    }
    return self.bossName;
end

---@param layers PowerLayer[] The layers to update.
---@param args table<unknown, unknown>[]? Extra parameters, typically passed in theough
---nvim_set_decoration_provider.
---@diagnostic disable-next-line: unused-local
function BossPreset.__prototype:UpdateWindow(layers, args)
    vim.schedule(function()
        self.win:AddLayer((unpack or table.unpack)(layers));
        self.win:RenderWindow();
        self.win:RenderComponents();
    end)
end

---@param group string | integer The identifier to put this group into.
---If an integer, the group must be preexisting.
function BossPreset.new(group)
    local group_string;
    if (type(group) == "number") then
        for _, v in pairs(vim.api.nvim_get_autocmds({ group = group })) do
            if (v.group_name) then
                group_string = v.group_name;
                break;
            end
        end

        assert(type(group_string) == "string", "failed to get group name from group id");
    elseif (type(group) == "string") then
        group_string = group;
        group = vim.api.nvim_create_augroup(group, {
            clear = false,
        })
    end

    --- no need to do some gigabrain class impl
    --- just need to return an obj that works

    ---@class Boss : BossPrototype A boss preset instance.
    local Boss = setmetatable({}, { __index = BossPreset.__prototype });
    local scorekeep = Scorekeep.new(group);
    local time_to_tick = 100;

    local timer = vim.loop.new_timer();
    timer:start(0, time_to_tick, function()
        vim.schedule(function()
            local scoreItem = scorekeep:Ensure();
            scorekeep:ScoreHandler(scoreItem);
            Boss:UpdateWindow({ Boss.bar, Boss.bar2 })
        end)
    end)

    ---comment
    ---@param scoreItem ScoreEntry
    scorekeep.ScoreUpdated = function(scoreItem)
        if (scoreItem.score >= scorekeep.scoreCap) then
            scoreItem.score = 0;
            Boss.bossName = nil;
        end
    end

    ---@param namespace integer
    function Boss:on_init(namespace)
        ---   stuff   ---

        local winwidth = vim.fn.winwidth(0);
        self.win = PowerWindow.new();
        self.win:SetAnchorType(AnchorType.ABSOLUTE);
        self.win:BindToNamespace(namespace);
        self.win.Width = "50%";
        self.win.X = (winwidth / 2) - (self.win.Width / 2)
        self.win.Y = "100%"


        self.bar = PowerLayer.new("Bar", namespace, self.win.__buf);
        self.bar2 = PowerLayer.new("Bar2", namespace, self.win.__buf);
        self.bar:BindWindow(self.win);
        self.bar2:BindWindow(self.win);
        self.win:Show();

        --- end stuff ---
    end

    function Boss:on_start()
        local healthBars = 5;
        local healthCap = math.floor(scorekeep.scoreCap / healthBars + 0.5);
        local scoreItem = scorekeep:Ensure();

        local score = (scoreItem.score / scorekeep.scoreCap);
        local score_inverse = 1 - score;
        local health_score = scoreItem.score / healthCap;

        for i = 1, healthBars - 1 do
            ---@type PowerLayer
            if (not self.colours[i]) then
                self.colours[i] = ("#%0.6X"):format(math.random(0xFFFFFF)):upper();
            end
        end

        self.bar:Clear();
        self.bar2:Clear();

        local text_col;
        local lolok = 1 - ((healthBars - 1) / healthBars);
        local floored_score = math.floor(health_score);
        if (score_inverse >= lolok) then
            text_col = self.colours[math.max(#self.colours - (floored_score), 0)]
            self.bar:Bar(0, 2, 1, self.colours[#self.colours - (floored_score + 1)]);
        else
            text_col = self.colours[0];
        end

        local normalized = 1 - (health_score % 1);
        self.bar2:Bar(0, 2, score == 1 and 0 or normalized, text_col);
        self.win:SetTitle(("%s (%s%%)"):format(Boss.bossName or self:RegenerateBossName(),
            math.floor(score_inverse * 100 + 0.25)));
        return true;
    end

    function Boss:on_update()
    end

    function Boss:cleanup()
        scorekeep.ScoreUpdated = nil;
        self.win:ClearLayers();
        self.win:Hide();

        vim.api.nvim_create_augroup(group_string, {
            clear = true,
        });
    end

    return Boss;
end

return BossPreset;
