-- @name proxy.lua
-- @rev 2024/03/26
-- @by Nowaaru
-- @license gpl3.0
--
-- @desc
-- Makes an interface that takes
-- metatable preservation into very, very
-- careful consideration.

local unpack = unpack or table.unpack;
local switch, case, default, fallthrough = unpack(require("power-mode.proxy.switch"));

---@class ProxyConstructor
---@field __VERBOSE boolean Whether the constructor should automatically log changes.
---@overload fun(of: table, proxyName?: string): Proxy
local ProxyConstructor = setmetatable({
    __VERBOSE = false,
}, {
    ---@generic T : table
    ---@param self ProxyConstructor The table responsible for this call.
    ---@param of T The table that will be turned into a proxy.
    ---@param proxyName? table The name of the proxy.
    ---
    ---@return Proxy<T> proxy An interface of "of."
    __call = function(self, of, proxyName)
        local isUnknown = type(of) ~= "table";

        local obj = of
        local ofMt = (function()
            local mt = getmetatable(of);
            local function eitherTypeIs(qualifier, ...)
                for _, v in pairs({ ... }) do
                    if (type(v) == qualifier) then
                        return true;
                    end
                end

                return false;
            end

            local types = function(...)
                local out = { ... };
                for i, v in pairs(out) do
                    out[i] = type(v);
                end

                return out;
            end

            return (type(mt) == "table" and mt or {});
        end)()

        for i, v in pairs(of) do
            obj[i] = v;
        end

        ---@nodiscard
        local proxyFunctionHandler = function(metamethod, ...)
            local maybe_func = rawget(ofMt, metamethod);
            if (type(maybe_func) == "function") then
                return maybe_func(...);
            end

            return maybe_func;
        end

        ---@class Proxy<T>
        -- apply second layer metatable to preserve object mt
        -- also prioritize previous __index before defaulting to
        -- `of` index.
        -- prioritize our __newindex (it prevents true writing)
        -- over the previous __newindex (but still call it as a side-effect)
        return setmetatable({},
            setmetatable({
                -- yoinked from LuaUsers
                __pairs = function()
                    local function stateless_iter(tbl, k)
                        local v;

                        k, v = next(tbl, k);
                        if nil ~= v then
                            return k, v;
                        end
                    end

                    return stateless_iter, obj, nil
                end,

                __index = function(_, k)
                    local maybe_func = rawget(obj, k);
                    -- print(("looking for [%s]: %s"):format(k, vim.inspect(obj)));
                    if (type(maybe_func) == "function") then
                        -- print("has! returning...");
                        return function(...)
                            local args = {...};
                            table.remove(args, 1)
                            maybe_func(obj, ...);
                        end
                    elseif (type(maybe_func) ~= "nil") then
                        -- print("has. returning")
                        return maybe_func;
                    end

                    local pfhResult = { proxyFunctionHandler("__index", obj, k) };
                    if ((table.maxn and table.maxn(pfhResult) or #pfhResult) == 0) then
                        return rawget(rawget(ofMt, "__index") or {}, k);
                    end

                    -- this solves a bug that makes methods
                    -- utilize a `self` that points to a potential
                    -- metatable instead of just `obj`
                    --
                    -- WARNING: this makes it impossible to makes
                    -- functions; every function has to be provided
                    -- through a metatable (but why give an object)
                    -- a function instead of a static class? :/
                    local maybe_func_self_mapped_to_obj = {};
                    for i, v in pairs(type(pfhResult[1]) == "table" and pfhResult[1] or {}) do
                        if (type(v) == "function") then
                            maybe_func_self_mapped_to_obj[i] = function(...)
                                -- print("ok then wb here");
                                local args = { ... }
                                table.remove(args, 1);
                                return rawget(rawget(pfhResult, 1), i)(of, unpack(args));
                            end
                        else
                            -- print('eyeye:', i);
                            maybe_func_self_mapped_to_obj[i] = v
                        end
                    end

                    return maybe_func_self_mapped_to_obj[k];
                end,
                __newindex = function(this, k, v)
                    local onPropertyChangedListener = rawget(obj, "__" .. k .. "Changed");
                    local typeofListener = type(onPropertyChangedListener);
                    local proxyId = proxyName or ("<anonymous:" .. tostring(this):gsub("table:", "") .. ">");
                    -- print(k, "->", v, vim.inspect(obj));
                    if (onPropertyChangedListener) then
                        if (typeofListener ~= "function") then
                            error(string.format(
                                "proxy (%s): property changed listener is not a function. (got %s)",
                                proxyId, type(onPropertyChangedListener)))
                        end

                        if (self.__VERBOSE) then
                            print(
                                string.format(
                                    "%s on proxy %s was changed. (%s -> %s)",
                                    k,
                                    proxyId,
                                    rawget(obj, k) or "<undefined>",
                                    type(v) ~= "nil" and v or "<undefined>"
                                ));
                        end

                        onPropertyChangedListener(this, rawget(obj, k), v);
                    end


                    -- rawset returns the first parameters
                    -- so if someone does return self it likely
                    -- means they set something, no need for
                    -- us to do it
                    local pfhResult = proxyFunctionHandler("__newindex", obj, k, v);
                    if (pfhResult == obj) then
                        -- print("obj pfhresult")
                        return;
                    end

                    rawset(obj, k, v)
                end
            }, ofMt))
    end
});

---@generic T : table
---@return Proxy<T> proxy An interface of "of".
ProxyConstructor.new = function(...)
    return getmetatable(ProxyConstructor).__call(ProxyConstructor, ...);
end

return ProxyConstructor;
