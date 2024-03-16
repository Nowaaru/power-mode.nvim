local ParticleWrapper = {
    assetsDir = "~/.powermode/assets/",
    debug = false,
};

function ParticleWrapper.WithImages(images, ...)
    local Particle = {
        __prototype = {
        };
    };

    Particle.__index = Particle.__prototype;

    if (images == Particle) then
        return images.WithImages(...)
    end

    function Particle.new(x, y, size, source)
        local obj = setmetatable({
            X = x or 0,
            Y = y or 0,
            Size = size,
            Source = ParticleWrapper.assetsDir .. "/" .. source,

            Id = tostring(math.random()),
            Rendered = false,
        }, Particle);

        obj._image = images.from_file(obj.Source, {
            geometry = {
                x = x,
                y = y,
                width = size,
                height = size,
            },
        });

        function obj:_onXChanged(oldValue, newValue)
            if (oldValue ~= newValue) then
                if (self.Rendered) then
                    local geometry = self:makeGeometry();
                    geometry.x = newValue;
                    self._image:render(geometry);
                    return;
                end

                self._image:move(newValue)
            end
        end

        function obj:_onYChanged(oldValue, newValue)
            if (oldValue ~= newValue) then
                if (self.Rendered) then
                    local geometry = self:makeGeometry();
                    geometry.y = newValue;
                    self._image:render(geometry);
                    return;
                end

                self._image:move(newValue)
            end
        end

        function obj:_onRenderedChanged(oldValue, newValue)
            if (oldValue ~= newValue) then
                if (not newValue) then
                    self._image:clear();
                    return;
                end

                print("Particle is being re-rendered.");
                self._image:render(self:makeGeometry())
            end
        end

        return setmetatable({}, {
            __index = obj,
            __newindex = function(self, k, v)
                local onPropertyChangedListener = rawget(obj, "_on" .. k .. "Changed");
                local typeofListener = type(onPropertyChangedListener);
                if (onPropertyChangedListener) then
                    if (typeofListener ~= "function") then
                        error(string.format(
                            "power-mode.nvim/particle: property changed listener is not a function. (got %s)",
                            type(onPropertyChangedListener)))
                    end

                    print(
                        string.format(
                            "%s on particle ID %s was changed. (%s -> %s)",
                            k,
                            obj.Id,
                            rawget(self, k) or "<undefined>",
                            type(v) ~= "nil" and v or "<undefined>"
                        ));
                    onPropertyChangedListener(self, rawget(self, k), v);
                end
                rawset(obj, k, v)
            end
        })
    end

    function Particle.__prototype:makeGeometry()
        return {
            x = self.X,
            y = self.Y,
            width = self.Size,
            height = self.Size,
        };
    end

    return Particle;
end

return ParticleWrapper;
