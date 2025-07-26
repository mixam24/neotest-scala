local types = require("neotest.types")
local lib = require("neotest.lib")
local utils = require("neotest-scala.utils")

---Get test ID from the test line output.
---@param output string
---@return string
local function get_test_id(output)
    local words = vim.split(output, " ", { trimempty = true })
    -- Strip the test success indicator prefix and time taken in ms suffix.
    table.remove(words, 1)
    table.remove(words)
    return table.concat(words, " ")
end

-- Get test results from the test output.
---@param output_lines string[]
---@return table<string, string>
local function get_test_results(output_lines)
    local test_results = {}
    for _, line in ipairs(output_lines) do
        line = utils.strip_ansi_chars(line)
        if vim.startswith(line, "+") then
            local test_id = get_test_id(line)
            test_results[test_id] = types.ResultStatus.passed
        elseif vim.startswith(line, "X") then
            local test_id = get_test_id(line)
            test_results[test_id] = types.ResultStatus.failed
        end
    end
    return test_results
end

---Extract results from the test output.
---@param tree neotest.Tree
---@param test_results table<string, string>
---@return table<string, neotest.Result>
local function get_results(tree, test_results)
    local no_results = vim.tbl_isempty(test_results)
    local results = {}
    for _, node in tree:iter_nodes() do
        local node = node:data()
        if no_results then
            results[node.id] = { status = types.ResultStatus.failed }
        else
            local name = string.gsub(string.sub(node.id, string.len(node.path), -1), "::", " ")
        end
    end
    return results
end

---@async
---@param result neotest.StrategyResult
---@param tree neotest.Tree
---@return table<string, neotest.Result>
return function(_, result, tree)
    local success, lines = pcall(lib.files.read_lines, result.output)
    if not success then
        return {}
    end
    local test_results = get_test_results(lines)
    return get_results(tree, test_results)
end
