local types = require("neotest.types")
local lib = require("neotest.lib")

---@async
---@param spec neotest.RunSpec
---@param result neotest.StrategyResult
---@return table<string, neotest.Result>
return function(spec, result, _)
    local success, lines = pcall(lib.files.read_lines, spec.context.results_path)
    if not success then
        if result.code ~= 0 then
            error(lib.files.read(result.output), vim.log.levels.ERROR)
        end
        return {}
    end
    local results = {}
    for _, line in ipairs(lines) do
        local event = vim.json.decode(line, { luanil = { object = true } })
        local status
        local error_msg
        local error_line = -1
        if event.eventType == "TestSucceeded" then
            status = types.ResultStatus.passed
        elseif event.eventType == "TestFailed" then
            status = types.ResultStatus.failed
            local traces = { event.throwable.message or "" }
            local trace_position
            if event.throwable.stackTraces then
                for k, v in ipairs(event.throwable.stackTraces) do
                    table.insert(traces, v.toString)
                    if v.className == event.suiteClassName then
                        --- apparently, indexing starts from 0...
                        error_line = v.lineNumber - 1
                        goto continue
                    end
                    if error_line > 0 then
                        trace_position = k
                        break
                    end
                    ::continue::
                end
            end
            error_msg = table.concat(traces, "\n", 1, trace_position)
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
        results[id] = { status = status, errors = {} }
        if error_msg then
            table.insert(results[id]["errors"], { line = error_line, message = error_msg })
            results[id]["short"] = error_msg
        end
        ::continue::
    end
    return results
end
