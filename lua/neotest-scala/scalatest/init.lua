local results = require("results")
local build_spec = require("build_spec")

---@return neotest-scala.Framework
local M = {
    get_test_results = results.get_test_results,
    build_command = build_spec.build_command,
    match_func = results.match_func,
}

return M
