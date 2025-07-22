local types = require("neotest.types")
local lib = require("neotest.lib")
local failed = require("neotest-scala.munit.results.failed")
local finished = require("neotest-scala.munit.results.finished")

---@async
---@param result neotest.StrategyResult
---@return table<string, neotest.Result>
return function(_, result, _)
    local results = {}
    local success, lines = pcall(lib.files.read_lines, result.output)
    if not success then
        return results
    end
    local suite_name = nil
    local test_name = nil
    local match = nil

    for _, line in pairs(lines) do
        local status = nil
        match = vim.lpeg.match(finished.test_suite_started, line)
        if match ~= nil then
            suite_name = match.suite_name
        end
        match = vim.lpeg.match(finished.test_finished, line)
        if match ~= nil then
            if suite_name == nil then
                error("Suite name is unknown!", vim.log.levels.ERROR)
            end
            test_name = match.test_name
            status = types.ResultStatus.passed
        end
        match = vim.lpeg.match(failed.test_failure, line)
        if match ~= nil then
            suite_name = match.suite_name
            test_name = match.test_name
            status = types.ResultStatus.failed
        end
        -- Example of IDs:
        -- Namespace: <Package name>.<Class name>
        -- my.package.name.SetSuite
        -- Test: <Package name>.<Class name>::<Test name>
        -- my.package.name.SetSuite::An empty Set should have size 0
        if suite_name ~= nil and test_name ~= nil and status then
            local id = suite_name .. "::" .. test_name
            results[id] = { status = status, errors = {} }
        end
    end
    return results
end
