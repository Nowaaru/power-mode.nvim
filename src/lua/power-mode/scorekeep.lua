---@class ScorekeepConstructor
local Scorekeep                               = {};
local euler                                   = 2.71828

local DefaultScoreHandler                     = function(self, scoreItem)
    -- local self.timerIntervalMs          = (1 / 60) * 1000;
    -- local
    --
    -- local self.
    -- local self.flowMaxMultiplier        = 2.87;
    --
    --


    local old_score = scoreItem.score;
    if scoreItem.length_prev == -1 then
        goto update_length;
    end
    do
        local modalMultipliers = self._modalMultipliers;

        --[[
            --do-end required to prevent scope-hopping
            --]]
        --[[
                    doesn't matter what the changes were! just needs
                    to be not nothing
                --]]
        --TODO: move into anywhere else please god
        scoreItem.consistency = self:calculateConsistency(scoreItem.combo);
        local currentMode = vim.api.nvim_get_mode().mode;
        local isCurrentModeNormal = currentMode == "n";
        local lengthDelta = (scoreItem.length_prev - scoreItem.length);
        local lengthDeltaAbs = math.abs(lengthDelta) * (modalMultipliers[currentMode] or 1)
        local lengthDeltaModalClamped = isCurrentModeNormal and math.log10(lengthDeltaAbs) or lengthDeltaAbs;
        local baseAddedScore = math.max(0, math.min(self.scoreCap,
            (self.scoreIncrease * lengthDeltaModalClamped * scoreItem.consistency) / (self.timerIntervalMs * 0.5)));


        scoreItem.time = scoreItem.time + self.timerIntervalMs;
        scoreItem.score = math.min(self.scoreCap, scoreItem.score + (baseAddedScore));

        if (scoreItem.state_decrease >= self.scoreDecreaseCount) then
            -- if (scoreItem.state_decrease % scoreDecreaseCount == 0) then
            scoreItem.score = math.max(
                scoreItem.score - math.abs((0.5 * self.scoreIncrease) / self.timerIntervalMs),
                0)
            -- end
        end

        if (scoreItem.time > self.timeBeforeComboRemovalMs) then
            scoreItem.combo = 0;
        end

        if (scoreItem.length == scoreItem.length_prev) then
            scoreItem.state_decrease = scoreItem.state_decrease + 1
            scoreItem.consistency = (scoreItem.consistency - self.consistencyDecreaseRate)
        else
            scoreItem.state_decrease = 0;
        end
    end

    ::update_length::
    scoreItem.length_prev = scoreItem.length;
    if self.ScoreUpdated then
        local cur_score = scoreItem.score;
        vim.schedule(function()
            if (old_score ~= cur_score) then
                self.ScoreUpdated(scoreItem);
            end
        end)
    end
end
local MakeDefaultScoreHandler                 = function(...)
    return setmetatable({}, {
        __tostring = "Default Score Handler",
        __call = DefaultScoreHandler(...)
    })
end

---@class ScorekeepPrototype
---@field _buffers table<string, ScoreEntry>
---@field _modalMultipliers table<string, number>
---@field scoreIncreaseTimer unknown
---@field ScoreUpdated function?
Scorekeep.__prototype                         = {
    --- WARNING: Modes not specified in this
    --- table will **not** be whitelisted.
    ScoreUpdated             = nil,
    scoreIncreaseTimer       = nil,

    timerIntervalMs          = (1 / 60) * 1000,
    timeBeforeComboRemovalMs = 15 * 1000, -- 15 seconds (testing, maybe permanent as a default?)

    flowMaxMultiplier        = 2.87,
    consistencyDecreaseRate  = nil,

    forceScoreCap            = false,
    scoreDecreaseCount       = 3,
    scoreIncrease            = 3,
    scoreCap                 = 120,

    ScoreHandler             = MakeDefaultScoreHandler,
    _buffers                 = {},
    _modalMultipliers        = {
        v = 2.5,
        n = 2,
        i = 1
    },

};

Scorekeep.__prototype.consistencyDecreaseRate = 1 / (math.pow(Scorekeep.__prototype.flowMaxMultiplier, 1.3)); -- @ 2.87 ~ 8% loss per tick;

function Scorekeep:MakeDefault()
    ---@class ScoreEntry
    ---@field length_prev integer The length of the buffer during the last pass.
    ---@field length integer The current length of the buffer.
    ---@field score number The score belonging to this buffer.
    ---@field time integer The remaining time before the combo resets.
    ---@field combo integer How long the user has been consistently typing.
    ---@field consistency number The consistency multiplier derived from the combo.
    ---@field state_decrease integer How many passes have occured without a notable change.
    return {
        length_prev = -1,
        length = -1,

        score = 0,
        time = 0,
        combo = 0,
        consistency = 0,
        state_decrease = 0,
    };
end

function Scorekeep.__prototype:Ensure(bufferId)
    bufferId = tostring(bufferId);
    local storeItem = self._buffers[bufferId];
    if (not storeItem) then
        storeItem = Scorekeep:MakeDefault();
        self._buffers[bufferId] = storeItem;
    end

    return storeItem;
end

function Scorekeep.__prototype:Get(bufferId)
    if (tonumber(bufferId) == 0 or tonumber(bufferId) == nil) then
        bufferId = tostring(vim.api.nvim_get_current_buf())
    end
    return self._buffers[tostring(bufferId)]
end

function Scorekeep.__prototype:on_buffer_text_changed(args)
    local managed_buf = self._buffers[tostring(args.buf)];
    if (not managed_buf) then
        return print("unmanaged buf:", args.buf)
    end

    local bufferOffset = 2; -- unsure why but the buffer length is always increased by 2 :thonk:
    local bufferLength = math.max(0, vim.fn.line2byte(vim.fn.line("$") + 1) - bufferOffset);

    local storeItem = self:Ensure(args.buf);
    storeItem.length = bufferLength;

    if (storeItem.length_prev ~= -1) then
        storeItem.combo = math.max(0, storeItem.combo + (storeItem.length - storeItem.length_prev));
    end

    storeItem.time = 0;           -- time should reset
    storeItem.state_decrease = 0; -- since they typed, resume combo
end

function Scorekeep.__prototype:Start()
    local fixedInterval = (self.timerIntervalMs < 1) and self.timerIntervalMs * 1000 or self.timerIntervalMs;
    self.scoreIncreaseTimer:start(0, fixedInterval, function()
        for _, scoreItem in pairs(self._buffers) do
            self:ScoreHandler(scoreItem)
        end
    end)
end

function Scorekeep.__prototype:Stop()
    self.scoreIncreaseTimer:stop();
end

function Scorekeep.__prototype:calculateConsistency(amountCharactersTyped, converge)
    converge = converge or self.flowMaxMultiplier;
    return 1 + math.max(1, math.min(converge, 0.8 * math.log(math.pow(amountCharactersTyped, 0.7), euler)));
end

---comment
---@param powerModeGroup integer
function Scorekeep.new(powerModeGroup)
    local obj = setmetatable({}, {
        __index = Scorekeep.__prototype,
    })

    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
        group = powerModeGroup,
        callback = function(args)
            obj:on_buffer_text_changed(args);
        end
    });

    obj.scoreIncreaseTimer = vim.loop.new_timer();
    return obj;
end

return Scorekeep
