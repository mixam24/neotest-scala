local M = {}

---Flatten first level of nested arrays
---@param ... any
---@return any[]
function M.tbl_flatten(...)
    ---@diagnostic disable-next-line: undefined-global
    return vim.iter(...):flatten():totable()
end

return M
