local VirtualText = {
    __prototype = {},
};

VirtualText.__prototype.__index = VirtualText.__prototype;

function VirtualText.new()
    return setmetatable({
        ephemeral = true;
    }, VirtualText.__prototype);
end

function VirtualText.__prototype:Render()
    -- use self as opts ^^
end

function VirtualText.__prototype:Update()
end
