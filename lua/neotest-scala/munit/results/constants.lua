local M = {}
--- COLORS
M.color = {}
M.color.green = vim.lpeg.P("\x1B[32m")
M.color.faint = vim.lpeg.P("\x1B[90m")
M.color.light_red = vim.lpeg.P("\x1B[91m")
M.color.normal = vim.lpeg.P("\x1B[0m")

M.color.ALL = M.color.green + M.color.faint + M.color.light_red + M.color.normal

--- ALPHA-NUMERIC CODES
M.code = {}
M.code.alpha_numeric = vim.lpeg.R("az", "AZ", "09")
M.code.numeric = vim.lpeg.R("09")
M.code.dot = vim.lpeg.S(".")
M.code.spaces = vim.lpeg.P(" ") ^ 1
M.code.any = vim.lpeg.P(1)

--- (RE)USABLE FRAGMENTS
M.fragment = {}
M.fragment.test_suite_name = vim.lpeg.Cg((M.code.alpha_numeric ^ 1 * M.code.dot ^ 0) ^ 1, "suite_name")
M.fragment.test_name = vim.lpeg.Cg((M.code.any - M.color.ALL) ^ 0, "test_name")
M.fragment.duration = vim.lpeg.Cg(M.code.numeric ^ 1 * M.code.dot ^ 0 * M.code.numeric ^ 0, "duration")
    * vim.lpeg.P("s")

return M
