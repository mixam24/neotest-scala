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
    local id = nil
    ---@type table<string>
    local traces = {}
    local error_line = -1

    local release_stack_trace = function()
        if #traces > 0 then
            local error_msg = table.concat(traces, "\n")
            --- The error line of the last code trace is used...
            table.insert(results[id]["errors"], { line = error_line, message = error_msg })
            results[id]["short"] = error_msg
            traces = {}
        end
    end

    for _, line in pairs(lines) do
        local status = nil

        match = vim.lpeg.match(finished.test_suite_started, line)
        if match ~= nil then
            suite_name = match.suite_name
        end
        match = vim.lpeg.match(finished.test_finished, line)
        if match ~= nil then
            --- before changing the id and resetting the traces
            --- we must release collected stack traces if any
            release_stack_trace()
            if suite_name == nil then
                error("Suite name is unknown!", vim.log.levels.ERROR)
            end
            test_name = match.test_name
            status = types.ResultStatus.passed
        end
        match = vim.lpeg.match(failed.test_failure, line)
        if match ~= nil then
            release_stack_trace()
            suite_name = match.suite_name
            test_name = match.test_name
            status = types.ResultStatus.failed
            traces = { match.error_message or "" }
        end

        --- Collect stack trace in case of failure
        match = vim.lpeg.match(failed.framework_trace, line)
        if match ~= nil then
            table.insert(traces, failed.cleaned_trace_line(line))
        end
        match = vim.lpeg.match(failed.code_trace, line)
        if match ~= nil then
            table.insert(traces, failed.cleaned_trace_line(line))
            local line = math.floor(match.error_line)
            if line then
                --- apparently, indexing starts from 0...
                error_line = line - 1
            else
                error(string.format("Can't convert %s to integer!", match.error_line))
            end
        end

        ---
        -- Example of IDs:
        -- Namespace: <Package name>.<Class name>
        -- my.package.name.SetSuite
        -- Test: <Package name>.<Class name>::<Test name>
        -- my.package.name.SetSuite::An empty Set should have size 0
        if suite_name ~= nil and test_name ~= nil and status then
            id = suite_name .. "::" .. test_name
            results[id] = { status = status, errors = {} }
        end
    end
    --- in case the last test scenario failed
    release_stack_trace()

    return results
end
