
-- TODO: make nvim buffer class that
-- keeps track of buffer changes and
-- pipes then through the NeovimPowerMode
-- singleton's scorekeeper

local NeovimPowerMode = {
    managed_buffers = {};
};
NeovimPowerMode.__prototype = {};

function NeovimPowerMode.__prototype:registerBuffer()
end

function NeovimPowerMode.__prototype:unregisterBuffer()
end

function NeovimPowerMode.__prototype:submitKeystroke()
end
