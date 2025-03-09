local types = require("neotest.types")
local lib = require("neotest.lib")
local utils = require("neotest.lib.func_util")

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
        local error_line
        if event.eventType == "TestSucceeded" then
            status = types.ResultStatus.passed
        elseif event.eventType == "TestFailed" then
            status = types.ResultStatus.failed
            local trace_position = event.throwable.depth + 1
            error_msg = table.concat({
                event.throwable.message or "",
                table.concat(
                    utils.map(function(k, v)
                        return k, v.toString
                    end, event.throwable.stackTraces),
                    "\n",
                    trace_position
                ),
            }, "\n")
            error_line = event.throwable.stackTraces[trace_position].lineNumber - 1
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
          -- stylua: ignore start
          ::continue::
        -- stylua: ignore end
    end
    return results
end
