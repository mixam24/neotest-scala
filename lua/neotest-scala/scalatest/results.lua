local types = require("neotest.types")
local lib = require("neotest.lib")
local utils = require("neotest-scala.utils")

---Check if line represents begining or ending of the section
---@param line string: a single line of the test output
local function check_for_context(line)
    local match
    local sanitized_string = utils.strip_ansi_chars(line)
    _, _, match = string.find(sanitized_string, "Suite Starting -- (.*)")
    if match then
        return { type = "namespace", event = "start", name = match }
    end
    _, _, match = string.find(sanitized_string, "Suite Completed -- (.*)")
    if match then
        return { type = "namespace", event = "end", name = match }
    end
    _, _, match = string.find(sanitized_string, "Test Started -- (.*)")
    if match then
        return { type = "test", event = "start", name = match }
    end
    _, _, match = string.find(sanitized_string, "Test Succeeded -- (.*)")
    if match then
        return { type = "test", event = "end", name = match }
    end
    _, _, match = string.find(sanitized_string, "TEST FAILED -- (.*)")
    if match then
        return { type = "test", event = "fail", name = match }
    end
    return nil
end

-- Get test results from the test output.
---@param output_lines string[]
---@return table<string, string>
local function get_test_results(output_lines)
    local test_results = {}
    for _, line in ipairs(output_lines) do
        local event = check_for_context(line)
        if event then
            print(vim.inspect(event))
        end
    end
    return test_results
end

-- Get test results from the test output.
---@param test_results table<string, string>
---@param position_id string
---@return string|nil
local function match_func(test_results, position_id)
    for test_id, result in pairs(test_results) do
        if position_id:match(test_id) then
            return result
        end
    end
    return nil
end

---Extract results from the test output.
---@param tree neotest.Tree
---@param test_results table<string, string>
---@param match_func nil|fun(test_results: table<string, string>, position_id :string):string|nil
---@return table<string, neotest.Result>
local function get_results(tree, test_results, match_func)
    local no_results = vim.tbl_isempty(test_results)
    local results = {}
    local events = get_test_results(test_results)
    for _, node in tree:iter_nodes() do
        local node = node:data()
        if no_results then
            print("No results...")
            results[node.id] = { status = types.ResultStatus.failed }
        else
            local name = string.gsub(string.sub(node.id, string.len(node.path), -1), "::", " ")
            print(name)
            if events[name] then
                print(vim.inspect(events[name]))
            end
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
        if data.type ~= "test" then
            print(vim.inspect(data))
        end
    end
    local test_results = get_test_results(lines)
    return get_results(tree, test_results, match_func)
end
