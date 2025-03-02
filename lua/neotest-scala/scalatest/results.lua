local types = require("neotest.types")
local lib = require("neotest.lib")

---@async
---@param spec neotest.RunSpec
---@param result neotest.StrategyResult
---@param tree neotest.Tree
---@return table<string, neotest.Result>
return function(spec, result, tree)
    local success, lines = pcall(lib.files.read_lines, spec.context.results_path)
    if not success then
        return {}
    end
    local results = {}
    for _, line in ipairs(lines) do
        local event = vim.json.decode(line, { luanil = { object = true } })
        local status
        if event.eventType == "TestSucceeded" then
            status = types.ResultStatus.passed
        elseif event.eventType == "TestFailed" then
            status = types.ResultStatus.failed
        elseif event.eventType == "TestSkipped" then
            status = types.ResultStatus.skipped
        else
            goto continue
        end
        -- Example of IDs:
        -- Namespace: <Absolute filepath>::<Class name>
        -- /.../tests/data/scalatest/projects/scala2/src/test/scala/scalatest/basic/SetSuite.scala::SetSuite
        -- Test: <Absolute filepath>::<Class name>::<Test name>
        -- /.../tests/data/scalatest/projects/scala2/src/test/scala/scalatest/basic/SetSuite.scala::SetSuite::An empty Set should have size 0
        local id = event.suiteClassName .. "::" .. event.testName
        results[id] = { status = status }
        -- stylua: ignore start
        ::continue::
        -- stylua: ignore end
    end
    return results
end
