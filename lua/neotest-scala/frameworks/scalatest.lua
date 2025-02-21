local utils = require("neotest-scala.utils")
local tresitter = require("neotest.lib.treesitter")

---Retrieves scala package identifiers from the given file
---@param file_path string: file path
---@return table: list of packages found
local function package_names(file_path)
    local query = [[
           ; -- Query --
           (package_clause
            name: (package_identifier) @test.name
           ) @test.definition
           ]]
    local packages = {}
    ---@diagnostic disable: missing-fields
    local tree = tresitter.parse_positions(file_path, query, { nested_tests = true, require_namespaces = false })
    ---@diagnostic enable: missing-fields
    for _, child in tree:iter_nodes() do
        local data = child:data()
        if data.type == "test" then
            table.insert(packages, 1, data.name)
        end
    end
    local length = #packages
    if length == 0 then
        error(("Con't find package name in '%s' file").format(file_path), vim.log.levels.ERROR)
    end
    if length > 1 then
        -- TODO: current assumption/limitation is that file contains exactly one package
        error(("More than one package name found in '%s' file").format(file_path), vim.log.levels.ERROR)
    end
    return packages
end

local function suite_names(file_path)
    local query = [[
          ; Matches: `object 'Name' ...`
          (object_definition
           name: (identifier) @test.name)
           @test.definition

          ; Matches: `class 'Name' ...`
          (class_definition
          name: (identifier) @test.name)
          @test.definition
           ]]
    local suites = {}
    local opts = { nested_tests = true, require_namespaces = false }
    local tree = tresitter.parse_positions(file_path, query, opts)
    for _, child in tree:iter_nodes() do
        local data = child:data()
        if data.type == "test" then
            table.insert(suites, 1, data.name)
        end
    end
    local length = #suites
    if length == 0 then
        error(string.format("Can't find any suite in '%s' file", file_path), vim.log.levels.ERROR)
    end
    return suites
end

---comment
---@param tree neotest.Tree Neotest tree to traverse
---@return TestArguments[]
local function suite_arguments(tree)
    local node = tree:data()
    if not node.type == "file" then
        error(string.format("Expected to receive a node of type 'file' but got '%s'", node.type, vim.log.levels.ERROR))
    end
    local package = package_names(node.path)[1]
    local suites = suite_names(node.path)
    local arguments = {}
    for _, suite in pairs(suites) do
        table.insert(arguments, { class = package .. "." .. suite })
    end
    return arguments
end

local function construct_test_name(node, passed_name)
    if passed_name then
        return node.name .. string.format(" %s ", node.func_name) .. passed_name
    else
        return node.name
    end
end

---@class TestArguments
---@field name string|nil
---@field class string|nil

---@param tree neotest.Tree Neotest tree to traverse
---@param args TestArguments already defined test arguments
---@return TestArguments|nil
local function test_arguments(tree, args)
    local node = tree:data()
    if node.type == "test" then
        local name = construct_test_name(node, args.name)
        return test_arguments(tree:parent(), vim.tbl_deep_extend("force", args, { name = name }))
    elseif node.type == "namespace" then
        local class
        if args.class then
            class = node.name .. "." .. args.class
        else
            class = node.name
        end
        return test_arguments(tree:parent(), vim.tbl_deep_extend("force", args, { class = class }))
    elseif node.type == "file" then
        local package = package_names(node.path)[1]
        if args.class then
            return vim.tbl_deep_extend("force", args, { class = package .. "." .. args.class })
        end
    else
        -- Need to run all suites -> pass to another function
        return nil
    end
end

--- Builds a command for running tests for the framework.
---@param runner string
---@param project string
---@param tree neotest.Tree
---@param name string
---@param extra_args table|string
---@return string[]
local function build_command(runner, project, tree, name, extra_args)
    local arguments = test_arguments(tree, {})
    if arguments then
        arguments = { arguments }
    else
        arguments = suite_arguments(tree)
    end
    if runner == "bloop" then
        local full_test_path
        if #arguments == 1 then
            full_test_path = { "-o", arguments[1].class, "--", "-oDU" }
            if arguments[1].name then
                full_test_path = vim.tbl_flatten({ full_test_path, { "-z", arguments[1].name } })
            end
            print(vim.inspect(full_test_path))
            return vim.tbl_flatten({ "bloop", "test", extra_args, project, full_test_path })
        else
            full_test_path = {}
            for _, arg in pairs(arguments) do
                full_test_path = vim.tbl_flatten({ full_test_path, { "-o", arg.class } })
            end
            print(vim.inspect(full_test_path))
            return vim.tbl_flatten({ "bloop", "test", extra_args, project, full_test_path, "--", "-oDU" })
        end
    end
    if not arguments.class then
        return vim.tbl_flatten({ "sbt", extra_args, project .. "/test", "--", "-oDU" })
    end
    -- TODO: Run sbt with colors, but figure out wich ainsi sequence need to be matched.
    return vim.tbl_flatten({
        "sbt",
        "--no-colors",
        extra_args,
        project .. "/testOnly ",
        { "--", "-oU", "-z", string.format('"%s"', arguments.name) },
    })
end

---Check if line represents begining or ending of the section
---@param line string: a single line of the test output
local function check_for_context(line)
    local match
    local sanitized_string = utils.strip_ansi_chars(line)
    _, _, match = string.find(sanitized_string, "Suite Starting -- (.*)")
    if match then
        return { type = "suite", event = "start", name = match }
    end
    _, _, match = string.find(sanitized_string, "Suite Completed -- (.*)")
    if match then
        return { type = "suite", event = "end", name = match }
    end
    print(line)
    return nil
end

-- Get test results from the test output.
---@param output_lines string[]
---@return table<string, string>
local function get_test_results(output_lines)
    local test_results = {}
    local test_namespace = nil
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

---@return neotest-scala.Framework
local M = {
    get_test_results = get_test_results,
    build_command = build_command,
    match_func = match_func,
}

return M
