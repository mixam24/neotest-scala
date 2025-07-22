local const = require("neotest-scala.munit.results.constants")
local color = const.color
local fragment = const.fragment
local code = const.code

local M = {}

local failed_test_abs_name = color.light_red
    * fragment.test_suite_name
    * color.normal
    * (vim.lpeg.P(".") * color.light_red * fragment.test_name * color.normal) ^ 0

--- See for details:
--- 1. https://github.com/scalameta/munit/blob/50aa2fff7880292bbfa7d6a0476270c8fe7ff28b/junit-interface/src/main/java/munit/internal/junitinterface/RunSettings.java#L162
--- 2. https://github.com/scalameta/munit/blob/50aa2fff7880292bbfa7d6a0476270c8fe7ff28b/junit-interface/src/main/java/munit/internal/junitinterface/EventDispatcher.java#L89

M.test_failure = vim.lpeg.Ct(
    color.light_red
        * vim.lpeg.P("==> X ")
        * color.normal
        * failed_test_abs_name
        * code.spaces
        * color.faint
        * fragment.duration
        * color.normal
        * code.any ^ 0
)

return M
