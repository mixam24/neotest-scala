local const = require("neotest-scala.munit.results.constants")
local utils = require("neotest-scala.munit.results.utils")
local color = const.color
local fragment = const.fragment
local code = const.code
local modifier = const.modifier

local M = {}

--- Test result
local failed_test_suite_name = utils.colored(color.light_red, fragment.test_suite_name)
local failed_test_name = utils.colored(color.light_red, fragment.test_name)
local failed_test_abs_name = failed_test_suite_name * (vim.lpeg.P(".") * failed_test_name) ^ 0

--- Stack traces
local error_message = vim.lpeg.Cg((code.any - color.ALL - modifier.ALL) ^ 0, "error_message")
local runtime_class_name =
    vim.lpeg.Cg(((code.alpha_numeric + vim.lpeg.P("$")) ^ 1 * code.dot ^ 0) ^ 1, "runtime_class_name")
--- We may want to change it in future...
local filename = (code.any - color.ALL) ^ 1
local erorr_line = vim.lpeg.Cg(code.numeric ^ 1, "error_line")

M.framework_trace = modifier.sbt_wrapper_code ^ 0
    * utils.colored(color.faint, code.spaces * vim.lpeg.P("at") * code.spaces)
    * utils.colored(color.faint, runtime_class_name)
    * utils.colored(color.faint, vim.lpeg.P("("))
    * utils.colored(color.faint, filename)
    * vim.lpeg.P(":")
    * utils.colored(color.faint, erorr_line)
    * utils.colored(color.faint, vim.lpeg.P(")"))
    * modifier.sbt_wrapper_code ^ 0

M.code_trace = vim.lpeg.Ct(
    modifier.sbt_wrapper_code ^ 0
        * utils.colored(color.high_intensity, code.spaces * vim.lpeg.P("at") * code.spaces)
        * utils.colored(color.high_intensity, runtime_class_name)
        * utils.colored(color.high_intensity, vim.lpeg.P("("))
        * utils.colored(color.high_intensity, filename)
        * vim.lpeg.P(":")
        * utils.colored(color.high_intensity, erorr_line)
        * utils.colored(color.high_intensity, vim.lpeg.P(")"))
        * modifier.sbt_wrapper_code ^ 0
)

---Removes color and modifier codes from the given stack trace string
---@param line string Colored stack trace line of text
---@return string
M.cleaned_trace_line = function(line)
    --- Any matched color code passed to the function...
    local pattern = vim.lpeg.Cs(((color.ALL + modifier.ALL) / function(_)
        return ""
    end + 1) ^ 0)
    return vim.lpeg.match(pattern, line)
end

--- See for details:
--- 1. https://github.com/scalameta/munit/blob/50aa2fff7880292bbfa7d6a0476270c8fe7ff28b/junit-interface/src/main/java/munit/internal/junitinterface/RunSettings.java#L162
--- 2. https://github.com/scalameta/munit/blob/50aa2fff7880292bbfa7d6a0476270c8fe7ff28b/junit-interface/src/main/java/munit/internal/junitinterface/EventDispatcher.java#L89

M.test_failure = vim.lpeg.Ct(
    modifier.sbt_wrapper_code ^ 0
        * utils.colored(color.light_red, vim.lpeg.P("==> X "))
        * failed_test_abs_name
        * code.spaces
        * utils.colored(color.faint, fragment.duration)
        * code.spaces
        * error_message
        * modifier.sbt_wrapper_code ^ 0
)

return M
