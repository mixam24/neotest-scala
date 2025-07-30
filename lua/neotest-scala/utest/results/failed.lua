local const = require("neotest-scala.utest.results.constants")
local color = const.color
local modifier = const.modifier
local fragment = const.fragment
local code = const.code

local M = {}

--- Test result

--- Stack traces
local error_message = vim.lpeg.Cg((code.any - color.ALL) ^ 0, "error_message")
local class_name = (code.alpha_numeric ^ 1 * code.dot ^ 0) ^ 1
local runtime_class_name = ((code.alpha_numeric + vim.lpeg.P("$")) ^ 1 * code.dot ^ 0) ^ 1
--- We may want to change it in future...
local runtime_method_name = runtime_class_name
--- We may want to change it in future...
local filename = (code.any - color.ALL) ^ 1
local erorr_line = vim.lpeg.Cg(code.numeric ^ 1, "error_line")

M.exception_trace = vim.lpeg.Ct(
    code.spaces
        * color.light_red
        * modifier.underlined_text_on
        * class_name
        * color.reset
        * modifier.underlined_text_off
        * vim.lpeg.P(":")
        * code.spaces
        * color.light_red
        * error_message
        * color.reset
)

M.code_trace = vim.lpeg.Ct(
    code.spaces
        * color.red
        * runtime_class_name
        * color.light_red
        * runtime_method_name
        * color.red
        * vim.lpeg.P("(")
        * color.light_red
        * filename
        * color.reset
        * vim.lpeg.P(":")
        * color.light_red
        * erorr_line
        * color.red
        * vim.lpeg.P(")")
        * color.reset
)

---Removes color codes from the given stack trace string
---@param line string Colored stack trace line of text
---@return string
M.cleaned_trace_line = function(line)
    --- Any matched color code passed to the function...
    local pattern = vim.lpeg.Cs(((color.ALL + modifier.ALL) / function(_)
        return ""
    end + 1) ^ 0)
    return vim.lpeg.match(pattern, line)
end

--- See for details: https://github.com/com-lihaoyi/utest/blob/cc0228fb26262e36584fd97a0c39fd64b7d652f6/utest/src/utest/framework/Formatter.scala#L180

M.test_failure = vim.lpeg.Ct(
    color.red
        * vim.lpeg.P("X")
        * color.reset
        * code.spaces
        --- NOTE: We will need to trim the last space because LPEG is greedy:
        --- 1. https://www.gammon.com.au/lpeg
        --- 2. https://github.com/com-lihaoyi/utest/blob/712b57602aa5192e504fa05cd3fdf0a28251978a/utest/src/utest/framework/Formatter.scala#L165
        * fragment.absolute_test_name
        * color.faint
        * fragment.duration
        * color.normal
)

return M
