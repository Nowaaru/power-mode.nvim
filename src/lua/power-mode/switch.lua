-- @name switch.lua
-- @by Nowaaru
-- @rev 2024/03/26
-- @license gpl3.0
--
-- @desc The worst, stupidest, dumbest little thing ever that
-- might also help another unfortunate soul. I present to you:
-- super-aesthetic bracket-based switch syntax in lua!
--
-- ..or just use parenthesis and make it not matter at all.
-- Why use it at that point?

assert(debug and debug.getlocal,
    "your environment is incombatible with switch.lua (missing " ..
    (debug and "function debug.local" or "debug namespace") .. ")");


local locals, getLocals; do
    local function itr(up)
        local i = 0;
        return function(_, _)
            i = i + 1;
            return debug.getlocal((up or 1) + 3, i);
        end
    end

    locals = function(up)
        return itr(up)
    end

    getLocals = function(up)
        local out = {};
        for i, v in locals(up) do
            out[i] = v;
        end

        return out;
    end
end


local fallthrough;
fallthrough = function()
    return fallthrough;
end

local makeCaseHandler = function(qualifier)
    return function(table_of_function)
        table_of_function = type(table_of_function) == "function" and { table_of_function } or table_of_function;
        table_of_function = (#table_of_function == 1 and table_of_function[1] == fallthrough and { function() end, fallthrough }) or
        table_of_function
        table_of_function[1] = type(table_of_function[1]) ~= "function" and
            function()
                return table_of_function[1]
            end or
            table_of_function[1]

        assert(#table_of_function == 1, "argument #1 'table_of_function' should have one function and no more");
        local _doFallthrough = table.remove(table_of_function, 2) == fallthrough;
        local self = { qualifier };
        self[2] =
            function(default_line)
                local mutableCallingEnvironment = getLocals(0);
                local callingEnvironment = {};
                for i, v in pairs(mutableCallingEnvironment) do
                    callingEnvironment[i] = v;
                end

                if (self.__default) then
                    local noDefault = callingEnvironment.__NODEFAULT
                    assert(not noDefault or noDefault == self[1],
                        "a 'default' function was already defined on line " .. (default_line or "<unknown>"))
                end

                print("the calling environment:", vim.inspect(callingEnvironment));
                assert(callingEnvironment.__SWITCH ~= nil,
                    "function 'default' can only be called inside of a 'switch' statement");

                return table_of_function[1], _doFallthrough;
            end

        return self;
    end
end

local function case(qualifier)
    return makeCaseHandler(qualifier);
end

local function default(arg)
    -- assert(_ENV.SWITCH, "default {...} can only be used in a switch statement.");
    local handler = makeCaseHandler(tostring({}):sub(7))(arg);
    handler.__default = true;

    return handler;
end

local function switch(qualifier)
    local casesFunc = function(cases)
        local defaultCase;
        local alreadyDefaultCase;
        local fallThrough;
        ---@diagnostic disable-next-line: unused-local, redefined-local
        local __SWITCH = true;
        for _, v in pairs(cases) do
            ---@diagnostic disable-next-line: unused-local, redefined-local
            local __NODEFAULT, __SWITCH = defaultCase and defaultCase[1] or nil, true;
            if (v[1] == qualifier or fallThrough) then
                local fn, fallthru = v[2]();
                fallThrough = fallthru;

                local res = { fn() };
                if (not fallThrough) then
                    return (unpack or table.unpack)(res);
                end
            elseif (v.__default) then
                local f = v[2](alreadyDefaultCase);
                local funcInfo = debug.getinfo(f, "S");

                if (not defaultCase) then
                    defaultCase = f;
                    alreadyDefaultCase = funcInfo.linedefined .. "-" .. funcInfo.lastlinedefined;
                end
            end
        end

        assert(defaultCase, "switch <qualifier: " .. tostring(qualifier) .. " > fell through without a default");
        local res = { defaultCase() };
        return (unpack or table.unpack)(res);
    end

    return casesFunc
end

return setmetatable(
    {
        switch = switch,
        case = case,
        default = default,
        fallthrough = fallthrough,
        switch,
        case,
        default,
        fallthrough
    },
    {
        __index = function()
            error("attempt to index a nil value");
        end
    });
