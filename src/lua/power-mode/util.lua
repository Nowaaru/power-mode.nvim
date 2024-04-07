local Utility = {};

---Returns the namespace by its name.
---@param namespace_name string
---@return integer | nil ns_id The ID of the namespace, if available.
function Utility:GetNamespaceByName(namespace_name)
    return vim.api.nvim_get_namespaces()[namespace_name];
end

---Returns the namespace by its name.
---@param ns_id string The ID of the namespace.
---@return string | nil namespace_name The name of the namespace, if available.
function Utility:GetNamespaceById(ns_id)
    for string_id, maybe_id in pairs(vim.api.nvim_get_namespaces()) do
        if (maybe_id == ns_id) then
            return string_id;
        end
    end
end

---@param ns_id_or_name string | integer The ID (or name) of the namespace.
---@return boolean exists Whether the namespace exists.
function Utility:NamespaceExists(ns_id_or_name)
    if (type(ns_id_or_name) == "string") then
        return not not self:GetNamespaceByName(ns_id_or_name);
    end
    return not not self:GetNamespaceById(ns_id_or_name --[[ @as string ]]);
end

return Utility;
