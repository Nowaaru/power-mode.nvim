local ParticleWrapper = {};

function ParticleWrapper.WithImages(images, ...)
    local Particles = {};

    if (images == Particles) then
        return images.WithImages(...)
    end

    local prototype = {};
    prototype._props = {
        X = 0,
        Y = 0,
        Size = 4,
        Source = "",

        __index = prototype,
    };

    prototype.__newindex = function(self, k, v)
        local onPropertyChangedListener = rawget(self, "_" .. k .. "Changed");
        local typeofListener = type(onPropertyChangedListener);
        if (onPropertyChangedListener) then
            if (typeofListener == "function") then
                onPropertyChangedListener(self, rawget(self, k), v);
            end

            error(string.format("power-mode.nvim/particle: property changed listener is not a function. (got %s)",
                type(onPropertyChangedListener)))
        end

        rawset(self._props, k, v)
    end

    function Particles.FromAttributes(attrs)
        local obj = {};
        for k, _ in pairs(prototype) do
            obj[k] = attrs[k];
        end

        return setmetatable(obj, prototype);
    end

    function Particles.new(x, y, size, source)
        local obj = {
            X = x,
            Y = y,
            Size = size,
            Source = source,

            Id = tostring(math.random()),
        };

        function obj:_onXChanged(old_X, new_X)
            print(string.format("X on particle ID %s was changed. (%s -> %s)", self.Id, old_X, new_X));
        end

        return setmetatable(obj, prototype);
    end

    return Particles;
end

return ParticleWrapper;
