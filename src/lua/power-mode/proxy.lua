---@class ProxyConstructor
---@overload fun(of: table): Proxy
local Proxy = setmetatable({
    __VERBOSE = false,
}, {
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


        local proxyFunctionHandler = function(metamethod, ...)
            local maybe_func = rawget(ofMt, metamethod);
            if (type(maybe_func) == "function") then
                return maybe_func(...);
            end
        end

        --a
        ---@class Proxy
        -- apply second layer metatable to preserve object mt
        -- also prioritize previous __index before defaulting to
        -- `of` index.
        -- prioritize our __newindex (it prevents true writing)
        -- over the previous __newindex (but still call it as a side-effect)
        return setmetatable({},
            setmetatable({
                __index = function(this, k)
                    local pfhResult = { proxyFunctionHandler("__index", obj, k) };
                    if ((table.maxn and table.maxn(pfhResult) or #pfhResult) == 0) then
                        return rawget(obj, k);
                    end

                    return unpack(pfhResult);
                end,
                __newindex = function(this, k, v)
                    local onPropertyChangedListener = rawget(obj, "_on" .. k .. "Changed");
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
                                    rawget(this, k) or "<undefined>",
                                    type(v) ~= "nil" and v or "<undefined>"
                                ));
                        end
                        onPropertyChangedListener(this, rawget(this, k), v);
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
Proxy.new = function(of)
    return getmetatable(Proxy).__call(of);
end


local a = Proxy { a = 4, }

return Proxy;
