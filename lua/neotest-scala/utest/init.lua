local results = require("results")
local build_spec = require("build_spec")

---@class neotest-scala.Framework
local M = {
    get_test_results = results,
    build_command = build_spec,
}

return M
