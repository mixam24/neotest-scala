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
            --- before changing the id and resetting the traces
            --- we must release collected stack traces if any
            release_stack_trace()
            local absolute_test_name = string.sub(match.absolute_test_name, 1, #match.absolute_test_name - 1)
            id = test_id_mapping[absolute_test_name]
            if id == nil then
                --- it can be so that log contains more tests than user asked to run
                --- e.g. if sbt version is old and buggy...
                goto continue
            end
            status = types.ResultStatus.failed
            results[id] = { status = status, errors = {} }
        end
        match = vim.lpeg.match(succeeded.test_success, line)
        if match ~= nil then
            --- before changing the id and resetting the traces
            --- we must release collected stack traces if any
            release_stack_trace()
            local absolute_test_name = string.sub(match.absolute_test_name, 1, #match.absolute_test_name - 1)
            id = test_id_mapping[absolute_test_name]
            if id == nil then
                --- it can be so that log contains more tests than user asked to run
                --- e.g. if sbt version is old and buggy...
                goto continue
            end
            status = types.ResultStatus.passed
            results[id] = { status = status, errors = {} }
        end
        match = vim.lpeg.match(failed.exception_trace, line)
        if match ~= nil then
            if id == nil then
                --- it can be so that log contains more tests than user asked to run
                --- e.g. if sbt version is old and buggy...
                goto continue
            end
            table.insert(traces, failed.cleaned_trace_line(line))
        end
        match = vim.lpeg.match(failed.code_trace, line)
        if match ~= nil then
            if id == nil then
                --- it can be so that log contains more tests than user asked to run
                --- e.g. if sbt version is old and buggy...
                goto continue
            end
            table.insert(traces, failed.cleaned_trace_line(line))
            local line = math.floor(match.error_line)
            if line then
                --- apparently, indexing starts from 0...
                error_line = line - 1
            else
                error(string.format("Can't convert %s to integer!", match.error_line))
            end
        end
        ::continue::
    end
    --- in case the last test scenario failed
    release_stack_trace()

    return results
end
