local Proxy = require("power-mode.proxy");
Proxy.__VERBOSE = true;

local mt = {
    __mode = "k"
};
local VirtualText = {
    __thread = setmetatable({}, mt),
}; do
    local namespace = vim.api.nvim_create_namespace("powermode.nvim");

    vim.api.nvim_set_decoration_provider(namespace, {
        start = function(tick)
            local __thread = { unpack(VirtualText.__thread) };

            for TextObject, Renderer in pairs(__thread) do
                Renderer(TextObject, tick);
            end

            VirtualText.__thread = setmetatable({}, mt);
        end
    });

    local _cur_buf = vim.api.nvim_get_current_buf();
    VirtualText.__prototype = {
        __namespace = namespace,
        __index = VirtualText.__prototype,
        __renderQueue = {},
        __readyToRender = false,
        __id = vim.api.nvim_buf_set_extmark(_cur_buf, namespace, 0, 0),

        buffer = vim.api.nvim_get_current_buf(),
        ephemeral = true,
        props = {
            end_line = 10,
            id = 1,
            virt_text = { { "demo", "IncSearch" } },
            virt_text_pos = "right_align",
        },
    }

    function VirtualText.__prototype:Render(line, col, opts)
        VirtualText.__thread[self] = function(textObject, tick)
            local regulated_buffer = self.buffer < 0 and 0 or self.buffer
            local mark = vim.api.nvim_buf_set_extmark(regulated_buffer, self.namespace, line or -1, col or -1,
                opts or self.props or {});

            self.__readyToRender = true;
            print("this thang rendered:", mark)
            return mark, namespace;
        end;
    end
end

function VirtualText.new()
    print("ns id:", ns_id);

    local line_num = 5;
    local col_num = 5;

    return Proxy(setmetatable({
        __readyToRenderChanged = function(from, to)
            print("from, to");
        end
    }, VirtualText.__prototype));
end
