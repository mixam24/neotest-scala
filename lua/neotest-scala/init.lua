local Path = require("plenary.path")
local lib = require("neotest.lib")
local utils = require("neotest.lib.func_util")

local Adapter = { name = "neotest-scala" }

---Find the project root directory given a current directory to work from.
---Should no root be found, the adapter can still be used in a non-project context if a test file matches.
---@async
---@return string | nil @Absolute root dir of test suite
Adapter.root = lib.files.match_root_pattern("build.sbt")

---@async
---@param file_path string
---@return boolean
function Adapter.is_test_file(file_path)
    if not vim.endswith(file_path, ".scala") then
        return false
    end
    local elems = vim.split(file_path, Path.path.sep)
    local file_name = string.lower(elems[#elems])
    local patterns = { "test", "spec", "suite" }
    for _, pattern in ipairs(patterns) do
        if string.find(file_name, pattern) then
            return true
        end
    end
    return false
end

---Filter directories when searching for test files
---@async
---@return boolean
function Adapter.filter_dir(_, _, _)
    return true
end

---Given a file path, parse all the tests within it.
---@async
---@param file_path string Absolute file path
---@return neotest.Tree | nil
---@diagnostic disable-next-line: unused-local
function Adapter.discover_positions(file_path)
    error("Not initialized!", vim.log.levels.ERROR)
end

---@param args neotest.RunArgs
---@return nil | neotest.RunSpec | neotest.RunSpec[]
---@diagnostic disable-next-line: unused-local
function Adapter.build_spec(args)
    error("Not initialized!", vim.log.levels.ERROR)
end

---@async
---@param spec neotest.RunSpec
---@param result neotest.StrategyResult
---@param tree neotest.Tree
---@return table<string, neotest.Result>
---@diagnostic disable-next-line: unused-local
function Adapter.results(spec, result, tree)
    error("Not initialized!", vim.log.levels.ERROR)
end

setmetatable(Adapter, {
    __call = function(_, opts)
        assert(opts.framework, "'framework' value is not defined in the adapter config!")
        assert(
            utils.index({ "munit", "utest", "scalatest" }, opts.framework),
            "'framework' value provided is not supported. Supported values: 'munit', 'utest', 'scalatest'"
        )
        assert(opts.runner, "'runner' value is not defined in the adapter config!")
        assert(
            utils.index({ "bloop", "sbt" }, opts.runner),
            "'runner' value provided is not supported. Supported values: 'sbt', 'bloop'"
        )
        assert(
            not (opts.java_home ~= nil and opts.runner ~= "sbt"),
            "'java_home' parameter can only be configured for 'sbt' runner"
        )
        local impl = {}
        if opts.framework == "scalatest" then
            impl = require("neotest-scala.scalatest")
        elseif opts.framework == "munit" then
            impl = require("neotest-scala.munit")
        elseif opts.framework == "utest" then
            impl = require("neotest-scala.utest")
        else
            error("Not implemented!", vim.log.levels.ERROR)
        end
        return vim.tbl_deep_extend("force", Adapter, impl(opts))
    end,
})

---@type neotest.Adapter
return Adapter
