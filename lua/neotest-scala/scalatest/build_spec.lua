local nio = require("nio")
local lib = require("neotest.lib")
local common = require("neotest-scala.common.build_spec")

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
        return { class = string.sub(node.id, 1, split_position - 1), name = string.sub(node.id, split_position + 2) }
    elseif node.type == "namespace" then
        return { class = node.id }
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
        return vim.tbl_flatten({ "bloop", "test", "--no-color", project, cli_args })
    end
    -- TODO: Make sure that sbt also works + add tests...
    if not arguments.class then
        return vim.tbl_flatten({ "sbt", project .. "/test", "--", "-fJ", path })
    end
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
        -- TODO: consider to add a config property to inform plugin that package names follow directory
        --  structure names.
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
