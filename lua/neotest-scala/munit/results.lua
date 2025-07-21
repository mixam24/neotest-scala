local utils = require("neotest-scala.utils")
local types = require("neotest.types")
local lib = require("neotest.lib")

---Get test ID from the test line output.
---@param output string
---@return string
local function get_test_name(output, prefix)
    return output:match("^" .. prefix .. " (.*) %d*%.?%d+s.*") or nil
end

---Get test namespace from the test line output.
---@param output string
---@return string|nil
local function get_test_namespace(output)
    return output:match("^([%w%.]+):") or nil
end

-- Get test results from the test output.
---@param output_lines string[]
---@return table<string, string>
local function get_test_results(output_lines)
    local test_results = {}
    local test_namespace = nil
    for _, line in ipairs(output_lines) do
        line = vim.trim(utils.strip_ansi_chars(line))
        local current_namespace = get_test_namespace(line)
        if current_namespace and (not test_namespace or test_namespace ~= current_namespace) then
            test_namespace = current_namespace
        end
        if test_namespace and vim.startswith(line, "+") then
            local test_name = get_test_name(line, "+")
            if test_name then
                local test_id = test_namespace .. "." .. vim.trim(test_name)
                test_results[test_id] = types.ResultStatus.passed
            end
        elseif test_namespace and vim.startswith(line, "==> X") then
            local test_name = get_test_name(line, "==> X")
            if test_name then
                test_results[vim.trim(test_name)] = types.ResultStatus.failed
            end
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
    local events = get_test_results(test_results)
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
---@param spec neotest.RunSpec
---@param result neotest.StrategyResult
---@param tree neotest.Tree
---@return table<string, neotest.Result>
return function(spec, result, tree)
    local success, lines = pcall(lib.files.read_lines, result.output)
    if not success then
        return {}
    end
    for _, child in tree:iter_nodes() do
        local data = child:data()
    end
    local test_results = get_test_results(lines)
    return get_results(tree, test_results)
end
