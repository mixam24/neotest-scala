local utils = require("neotest-scala.utils")

-- Builds a test path from the current position in the tree.
---@param tree neotest.Tree
---@param name string
---@return string|nil
local function build_test_path(tree, name)
    local parent_tree = tree:parent()
    local type = tree:data().type
    if parent_tree and parent_tree:data().type == "namespace" then
        local package = utils.get_package_name(parent_tree:data().path)
        local parent_name = parent_tree:data().name
        return package .. parent_name .. "." .. name
    end
    if parent_tree and parent_tree:data().type == "test" then
        local parent_pos = parent_tree:data()
        return build_test_path(parent_tree, utils.get_position_name(parent_pos)) .. "." .. name
    end
    if type == "namespace" then
        local package = utils.get_package_name(tree:data().path)
        if not package then
            return nil
        end
        return package .. name
    end
    if type == "file" then
        local test_suites = {}
        for _, child in tree:iter_nodes() do
            if child:data().type == "namespace" then
                table.insert(test_suites, child:data().name)
            end
        end
        if test_suites then
            local package = utils.get_package_name(tree:data().path)
            return package .. "{" .. table.concat(test_suites, ",") .. "}"
        end
    end
    if type == "dir" then
        local packages = {}
        local visited = {}
        for _, child in tree:iter_nodes() do
            if child:data().type == "namespace" then
                local package = utils.get_package_name(child:data().path)
                if package and not visited[package] then
                    table.insert(packages, package:sub(1, -2))
                    visited[package] = true
                end
            end
        end
        if packages then
            return "{" .. table.concat(packages, ",") .. "}"
        end
    end
    return nil
end

--- Builds a command for running tests for the framework.
---@param runner string
---@param project string
---@param tree neotest.Tree
---@param name string
---@param extra_args table|string
---@return string[]
local function build_command(runner, project, tree, name, extra_args)
    local test_path = build_test_path(tree, name)
    return utils.build_command_with_test_path(project, runner, test_path, extra_args)
end

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
            test_results[test_id] = TEST_PASSED
        elseif vim.startswith(line, "X") then
            local test_id = get_test_id(line)
            test_results[test_id] = TEST_FAILED
        end
    end
    return test_results
end

---@class neotest-scala.Framework
local M = {
    get_test_results = get_test_results,
    build_command = build_command,
}

return M
