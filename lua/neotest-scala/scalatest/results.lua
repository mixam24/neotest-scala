local types = require("neotest.types")
local lib = require("neotest.lib")

---@async
---@param spec neotest.RunSpec
---@return table<string, neotest.Result>
return function(spec, _, _)
    local success, lines = pcall(lib.files.read_lines, spec.context.results_path)
    if not success then
        return {}
    end
    local results = {}
    for _, line in ipairs(lines) do
        local event = vim.json.decode(line, { luanil = { object = true } })
        local status
        local error_msg
        local error_line
        if event.eventType == "TestSucceeded" then
            status = types.ResultStatus.passed
        elseif event.eventType == "TestFailed" then
            status = types.ResultStatus.failed
            local trace_position = event.throwable.depth + 1
            error_msg = event.throwable.stackTraces[trace_position].toString
            error_line = event.throwable.stackTraces[trace_position].lineNumber
        elseif event.eventType == "TestSkipped" then
            status = types.ResultStatus.skipped
        else
            goto continue
        end
        -- Example of IDs:
        -- Namespace: <Package name>.<Class name>
        -- my.package.name.SetSuite
        -- Test: <Package name>.<Class name>::<Test name>
        -- my.package.name.SetSuite::An empty Set should have size 0
        local id = event.suiteClassName .. "::" .. event.testName
        results[id] = { status = status, output = spec.context.results_path }
        if error_msg then
            results[id]["errors"] = { line = error_line, message = error_msg }
        end
          -- stylua: ignore start
          ::continue::
        -- stylua: ignore end
    end
    return results
end
