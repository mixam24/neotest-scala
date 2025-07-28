local types = require("neotest.types")
local lib = require("neotest.lib")
local failed = require("neotest-scala.utest.results.failed")
local succeeded = require("neotest-scala.utest.results.succeeded")

---@async
---@param result neotest.StrategyResult
---@param tree neotest.Tree
---@return table<string, neotest.Result>
return function(_, result, tree)
    local results = {}
    local success, lines = pcall(lib.files.read_lines, result.output)
    if not success then
        return results
    end
    local match = nil
    local id = nil

    --- We need to build the mapping between test IDs and output of the utest...
    local test_id_mapping = {}
    for _, node in tree:iter_nodes() do
        local info = node:data()
        if info.type ~= "test" then
            goto continue
        end
        local split_position = string.find(info.id, "::")
        local key = string.sub(info.id, 1, split_position - 1) .. "." .. string.sub(info.id, split_position + 2)
        test_id_mapping[key] = info.id
        ::continue::
    end

    for _, line in pairs(lines) do
        local status = nil

        match = vim.lpeg.match(failed.test_failure, line)
        if match ~= nil then
            local absolute_test_name = string.sub(match.absolute_test_name, 1, #match.absolute_test_name - 1)
            id = test_id_mapping[absolute_test_name]
            status = types.ResultStatus.failed
            results[id] = { status = status, errors = {} }
        end
        match = vim.lpeg.match(succeeded.test_success, line)
        if match ~= nil then
            local absolute_test_name = string.sub(match.absolute_test_name, 1, #match.absolute_test_name - 1)
            id = test_id_mapping[absolute_test_name]
            status = types.ResultStatus.passed
            results[id] = { status = status, errors = {} }
        end
    end

    return results
end
