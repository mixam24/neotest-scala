local discover_positions = require("neotest-scala.scalatest.discover_positions")
local results = require("neotest-scala.scalatest.results")
local build_spec = require("neotest-scala.scalatest.build_spec")
local utils = require("neotest.lib.func_util")

local M = {}

---@class FrameworkArgs
---@field runner string Name of the runner to use

setmetatable(M, {
    ---comment
    ---@param opts FrameworkArgs
    ---@return table
    __call = function(_, opts)
        assert(opts.runner, "'runner' value is not defined in the adapter config!")
        assert(
            utils.index({ "bloop", "sbt" }, opts.runner),
            "'runner' value provided is not supported with 'scalatest' framework. Supported values: 'sbt', 'bloop'"
        )
        M.results = results
        M.build_spec = function(args)
            return build_spec(opts.runner, args)
        end
        M.discover_positions = discover_positions
        return M
    end,
})

return M
