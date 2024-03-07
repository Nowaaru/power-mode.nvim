local module = {};

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

function module:Setup(...)
    return module:setup(unpack({...})); -- error wouldn't shut up :/
end

function module:setup()
    local supportsImages, imageNvim = pcall(function()
        return require("image");
    end);

    self:assert(supportsImages, "unable to locate plugin '3rd/image.nvim.'");
    print("3rd/image.nvim successfully found.");

    self:__test(imageNvim);
end

function module:__test(imageNvim)
    local Particles = require("power-mode.particle"):WithImages(imageNvim);
    
    local newParticle = Particles.new();
    newParticle.X = 25;
end

return module;
