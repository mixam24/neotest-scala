local nio = require("nio")
local lib = require("neotest.lib")
local common = require("neotest-scala.common.build_spec")
local tresitter = require("neotest.lib.treesitter")
local utils = require("neotest-scala.utils")
local types = require("neotest.types")

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
            full_test_path = { "-o", arguments[1].class, "--", "-oU" }
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
            return vim.tbl_flatten({ "bloop", "test", extra_args, project, full_test_path, "--", "-oU" })
        end
    end
    if not arguments.class then
        return vim.tbl_flatten({ "sbt", extra_args, project .. "/test", "--", "-oU" })
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

---@param runner string Name of the runner
---@param args neotest.RunArgs
---@return nil | neotest.RunSpec | neotest.RunSpec[]
return function(runner, args)
    local position = args.tree:data()
    if position.type == "dir" then
        -- NOTE:Although IT’S NOT REQUIRED, package names typically follow directory structure names.
        -- I.e. it is not safe to build spec for dir and we need to process each test file in dir.
        -- Source: https://docs.scala-lang.org/scala3/book/packaging-imports.html
        return nil
    end
    assert(lib.func_util.index({ "bloop", "sbt" }, runner), "set sbt or bloop runner")
    local project = common.get_project_name(position.path, runner)
    assert(project, "scala project not found in the build file")
    local extra_args = args.extra_args or {}
    local command = build_command(runner, project, args.tree, utils.get_position_name(position), extra_args)
    local strategy = common.get_strategy_config(args.strategy, args.tree, project)
    local results_path = nio.fn.tempname()
    lib.files.write(results_path, "")
    local stream_data, stop_stream = lib.files.stream_lines(results_path)
    return {
        command = command,
        strategy = strategy,
        context = {
            results_path = results_path,
            stop_stream = stop_stream,
        },
        stream = function()
            return function()
                local lines = stream_data()
                local results = {}
                for _, line in ipairs(lines) do
                    local event = vim.json.decode(line, { luanil = { object = true } })
                    local result
                    if event.eventType == "TestSucceeded" then
                        result = types.ResultStatus.passed
                    elseif event.eventType == "TestFailed" then
                        result = types.ResultStatus.failed
                    elseif event.eventType == "TestSkipped" then
                        result = types.ResultStatus.skipped
                    else
                        goto continue
                    end
                    local id = event.suiteClassName .. "::" .. event.testName
                    results[id] = result
                    ::continue::
                end
                return results
            end
        end,
    }
end
