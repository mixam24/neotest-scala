local const = require("neotest-scala.utest.results.constants")
local color = const.color
local fragment = const.fragment
local code = const.code

local M = {}

--- Test result

--- See for details: https://github.com/com-lihaoyi/utest/blob/cc0228fb26262e36584fd97a0c39fd64b7d652f6/utest/src/utest/framework/Formatter.scala#L180

M.test_success = vim.lpeg.Ct(
    color.green
        * vim.lpeg.P("+")
        * color.reset
        * code.spaces
        --- NOTE: We will need to trim the last space because the LPEG is greedy:
        --- 1. https://www.gammon.com.au/lpeg
        --- 2. https://github.com/com-lihaoyi/utest/blob/712b57602aa5192e504fa05cd3fdf0a28251978a/utest/src/utest/framework/Formatter.scala#L165
        * fragment.absolute_test_name
        * color.faint
        * fragment.duration
        * color.normal
        * (code.spaces * color.blue * code.numeric * color.reset) ^ 0
)

return M
