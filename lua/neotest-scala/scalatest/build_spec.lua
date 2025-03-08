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

---@class TestArguments
---@field name string|nil
---@field class string|nil
---@field pkg string|nil

---@param tree neotest.Tree Neotest tree to traverse
---@return TestArguments
local function test_arguments(tree)
    local node = tree:data()
    if node.type == "test" then
        local split_position = string.find(node.id, "::")
        return { class = string.sub(node.id, 1, split_position), name = string.sub(node.id, split_position + 2) }
    elseif node.type == "namespace" then
        return { class = node.id }
    elseif node.type == "file" then
        return { pkg = node.id }
    else
        -- It should never happen...
        error("Should never happen...", vim.log.levels.ERROR)
    end
end

--- Builds a command for running tests for the framework.
---@param runner string
---@param project string
---@param tree neotest.Tree
---@param path string Path to the temp file for results output
---@return string[]
local function build_command(runner, project, tree, path)
    local arguments = test_arguments(tree)
    if runner == "bloop" then
        local cli_args
        if arguments.pkg then
            cli_args = { "-m", arguments.pkg, "--", "-fJ", path }
        elseif arguments.name then
            cli_args = { "-o", arguments.class, "--", "-fJ", path, "-z", arguments.name }
        else
            cli_args = { "-o", arguments.class, "--", "-fJ", path }
        end
        return vim.tbl_flatten({ "bloop", "test", project, cli_args })
    end
    if not arguments.class then
        return vim.tbl_flatten({ "sbt", project .. "/test", "--", "-fJ", path })
    end
    -- TODO: Run sbt with colors, but figure out wich ainsi sequence need to be matched.
    return vim.tbl_flatten({
        "sbt",
        "--no-colors",
        project .. "/testOnly ",
        { "--", "-fJ", path, "-z", string.format('"%s"', arguments.name) },
    })
end

---@param runner string Name of the runner
---@param args neotest.RunArgs
---@return nil | neotest.RunSpec | neotest.RunSpec[]
return function(runner, args)
    local position = args.tree:data()
    if lib.func_util.index({ "dir", "file" }, position.type) then
        -- NOTE:Although IT’S NOT REQUIRED, package names typically follow directory structure names.
        -- I.e. it is not safe to build spec for dir or file and we need to process each test file in dir.
        -- Source: https://docs.scala-lang.org/scala3/book/packaging-imports.html
        return nil
    end
    assert(lib.func_util.index({ "bloop", "sbt" }, runner), "set sbt or bloop runner")
    local project = common.get_project_name(position.path, runner)
    assert(project, "scala project not found in the build file")
    local results_path = nio.fn.tempname()
    local command = build_command(runner, project, args.tree, results_path)
    local strategy = common.get_strategy_config(args.strategy, args.tree, project)
    return {
        command = command,
        strategy = strategy,
        context = {
            results_path = results_path,
        },
    }
end
