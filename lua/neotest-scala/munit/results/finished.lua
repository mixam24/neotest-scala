local const = require("neotest-scala.munit.results.constants")
local color = const.color
local fragment = const.fragment
local code = const.code
local modifier = const.modifier

local M = {}

--- See for details:
--- 1. https://github.com/scalameta/munit/blob/50aa2fff7880292bbfa7d6a0476270c8fe7ff28b/junit-interface/src/main/java/munit/internal/junitinterface/RunSettings.java#L162
--- 2. https://github.com/scalameta/munit/blob/50aa2fff7880292bbfa7d6a0476270c8fe7ff28b/junit-interface/src/main/java/munit/internal/junitinterface/EventDispatcher.java#L165
--- 3. https://github.com/scalameta/munit/blob/50aa2fff7880292bbfa7d6a0476270c8fe7ff28b/junit-interface/src/main/java/munit/internal/junitinterface/EventDispatcher.java#L118

M.test_suite_started = vim.lpeg.Ct(
    modifier.sbt_wrapper_code ^ 0
        * color.green
        * fragment.test_suite_name
        * vim.lpeg.P(":")
        * color.normal
        * modifier.sbt_wrapper_code ^ 0
)
M.test_finished = vim.lpeg.Ct(
    modifier.sbt_wrapper_code ^ 0
        * color.green
        * vim.lpeg.P("  + ")
        * color.normal
        * color.green
        * fragment.test_name
        * color.normal
        * code.spaces
        * color.faint
        * fragment.duration
        * color.normal
        * modifier.sbt_wrapper_code ^ 0
)

return M
