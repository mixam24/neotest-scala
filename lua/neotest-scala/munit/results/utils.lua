local color = require("neotest-scala.munit.results.constants").color
local M = {}

---Returns colored text
---@param color_code vim.lpeg.Pattern LPEG pattern that represents color code to use
---@param text vim.lpeg.Capture|vim.lpeg.Pattern LPEG expression that represents text that needs to be colored
---@return vim.lpeg.Pattern
M.colored = function(color_code, text)
    return color_code * text * color.normal
end

return M
