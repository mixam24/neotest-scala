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
---@return string[]
local function build_command(runner, project, tree)
    local runner_args
    local test_command_args = {}
    local framework_args = { "--" }

    if runner == "bloop" then
        runner_args = { "bloop", "test", project }
    elseif runner == "sbt" then
        runner_args = { "sbt", project .. "/testOnly" }
    else
        error("Should never happen...", vim.log.levels.ERROR)
    end

    local arguments = test_arguments(tree)
    --- TODO: should we remove pkg from the TestArguments?
    ---  It is not in use...
    if arguments.pkg then
        if runner == "sbt" then
            test_command_args = { arguments.pkg }
        else
            framework_args = vim.tbl_flatten({ framework_args, string.format("%s.*", arguments.pkg) })
        end
    elseif arguments.name then
        if runner == "sbt" then
            test_command_args = { string.format('"%s.%s"', arguments.class, arguments.name) }
        else
            framework_args =
                vim.tbl_flatten({ framework_args, string.format("%s.%s", arguments.class, arguments.name) })
        end
    else
        if runner == "sbt" then
            test_command_args = { string.format("%s.*", arguments.class) }
        else
            framework_args = vim.tbl_flatten({ framework_args, string.format("%s.*", arguments.class) })
        end
    end
    return vim.tbl_flatten({ runner_args, test_command_args, framework_args })
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
    local command = build_command(runner, project, args.tree)
    local strategy = common.get_strategy_config(args.strategy, args.tree, project)
    return {
        command = command,
        strategy = strategy,
        context = {},
    }
end
