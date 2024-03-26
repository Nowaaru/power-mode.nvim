-- @name Proxy
-- @rev 2024/03/26
-- @by Nowaaru
-- @license gpl3.0
--
-- @desc
-- Makes an interface that takes
-- metatable preservation into very, very
-- careful consideration.

---@class ProxyConstructor
---@field __VERBOSE string Whether the constructor should automatically log changes.
---@overload fun(self: ProxyConstructor, of: table, proxyName?: string): Proxy
local ProxyConstructor = setmetatable({
    __VERBOSE = false,
}, {
    ---@param self ProxyConstructor The table responsible for this call.
    ---@param of table The table that will be turned into a proxy.
    ---@param proxyName? table The name of the proxy.
    ---
    ---@return Proxy proxy An interface of "of."
    __call = function(self, of, proxyName)
        local obj = {};
        local ofMt = (function()
            local mt = getmetatable(of);
            return type(mt) == "table" and mt or {};
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
        end

        ---@class Proxy
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
                    local pfhResult = { proxyFunctionHandler("__index", obj, k) };
                    if ((table.maxn and table.maxn(pfhResult) or #pfhResult) == 0) then
                        return rawget(obj, k);
                    end

                    return unpack(pfhResult);
                end,
                __newindex = function(this, k, v)
                    local onPropertyChangedListener = rawget(obj, "__" .. k .. "Changed");
                    local typeofListener = type(onPropertyChangedListener);
                    if (onPropertyChangedListener) then
                        if (typeofListener ~= "function") then
                            error(string.format(
                                "power-mode.nvim/particle: property changed listener is not a function. (got %s)",
                                type(onPropertyChangedListener)))
                        end

                        if (self.__VERBOSE) then
                            print(
                                string.format(
                                    "%s on proxy %s was changed. (%s -> %s)",
                                    k,
                                    proxyName or ("<anonymous: %s>"):format(tostring(this):gsub("table:", "")),
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
                        return;
                    end
                    rawset(obj, k, v)
                end
            }, ofMt))
    end
});

---@return Proxy proxy An interface of "of".
ProxyConstructor.new = function(...)
    return getmetatable(ProxyConstructor).__call(ProxyConstructor, ...);
end

return ProxyConstructor;
