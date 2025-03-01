local lib = require("neotest.lib")
local fw = require("neotest-scala.framework")
local utils = require("neotest-scala.utils")

local M = {}

M.root = lib.files.match_root_pattern("build.sbt")

local function get_runner()
    local vim_test_runner = vim.g["test#scala#runner"]
    if vim_test_runner == "blooptest" then
        return "bloop"
    end
    if vim_test_runner and lib.func_util.index({ "bloop", "sbt" }, vim_test_runner) then
        return vim_test_runner
    end
    return "bloop"
end

---@param pos neotest.Position
---@return string
local get_parent_name = function(pos)
    if pos.type == "dir" or pos.type == "file" then
        return ""
    end
    if pos.type == "namespace" then
        return utils.get_package_name(pos.path) .. pos.name
    end
    return utils.get_position_name(pos)
end

local function get_args()
    return {}
end

---Get first project name from bloop projects.
---@return string|nil
local function get_bloop_project_name()
    local command = "bloop projects"
    local handle = assert(io.popen(command), string.format("unable to execute: [%s]", command))
    local result = handle:read("*l")
    handle:close()
    return result
end

---Get project name from build file.
---@return string|nil
local function get_project_name(path, runner)
    local root = M.root(path)
    local build_file = root .. "/build.sbt"
    local success, lines = pcall(lib.files.read_lines, build_file)
    if not success then
        return nil
    end
    for _, line in ipairs(lines) do
        local project = line:match('^name := "(.+)"')
        if project then
            return project
        end
    end
    if runner == "bloop" then
        local bloop_project = get_bloop_project_name()
        if bloop_project then
            return bloop_project
        end
    end
    return nil
end

---Builds strategy configuration for running tests.
---@param strategy string
---@param tree neotest.Tree
---@param project string
---@return table|nil
local function get_strategy_config(strategy, tree, project)
    local position = tree:data()
    if strategy ~= "dap" or position.type == "dir" then
        return nil
    end
    if position.type == "file" then
        return {
            type = "scala",
            request = "launch",
            name = "NeotestScala",
            metals = {
                runType = "testFile",
                path = position.path,
            },
        }
    end
    local metals_arguments = nil
    if position.type == "namespace" then
        metals_arguments = {
            testClass = utils.get_package_name(position.path) .. position.name,
        }
    end
    if position.type == "test" then
        local root = M.root(position.path)
        local parent = tree:parent():data()
        vim.uri_from_fname(root)
        -- Constructs ScalaTestSuitesDebugRequest request.
        metals_arguments = {
            target = { uri = "file:" .. root .. "/?id=" .. project .. "-test" },
            requestData = {
                suites = {
                    {
                        className = get_parent_name(parent),
                        tests = { utils.get_position_name(position) },
                    },
                },
                jvmOptions = {},
                environmentVariables = {},
            },
        }
    end
    if metals_arguments ~= nil then
        return {
            type = "scala",
            request = "launch",
            -- NOTE: The `from_lens` is set here because nvim-metals passes the
            -- complete `metals` param to metals server without modifying
            -- (reading) it.
            name = "from_lens",
            metals = metals_arguments,
        }
    end
    return nil
end

---@async
---@param args neotest.RunArgs
---@return nil|neotest.RunSpec|neotest.RunSpec[]
function M.build_spec(args)
    local position = args.tree:data()
    if position.type == "dir" then
        -- NOTE:Although IT’S NOT REQUIRED, package names typically follow directory structure names.
        -- I.e. it is not safe to build spec for dir and we need to process each test file in dir.
        -- Source: https://docs.scala-lang.org/scala3/book/packaging-imports.html
        return nil
    end
    local runner = get_runner()
    assert(lib.func_util.index({ "bloop", "sbt" }, runner), "set sbt or bloop runner")
    local project = get_project_name(position.path, runner)
    assert(project, "scala project not found in the build file")
    local framework = fw.get_framework_class(get_framework())
    if not framework then
        return {}
    end
    local extra_args = vim.list_extend(get_args(), args.extra_args or {})
    local command = framework.build_command(runner, project, args.tree, utils.get_position_name(position), extra_args)
    local strategy = get_strategy_config(args.strategy, args.tree, project)
    return { command = command, strategy = strategy }
end

return M
