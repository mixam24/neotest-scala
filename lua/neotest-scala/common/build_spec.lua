local lib = require("neotest.lib")
local utils = require("neotest-scala.utils")

local M = {}

M.root = lib.files.match_root_pattern("build.sbt")

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
function M.get_project_name(path, runner)
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
function M.get_strategy_config(strategy, tree, project)
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

---Returns runner arguments from the given framework arguments
---@param frags FrameworkArgs Framework arguments
---@param project string Project name in which tests are defined
function M.get_runner_arguments(fargs, project)
    local args
    if fargs.runner == "bloop" then
        args = { "bloop", "test", project }
    elseif fargs.runner == "sbt" then
        args = {
            "sbt",
            "-Dsbt.supershell=false",
        }
        if fargs.java_home ~= nil then
            args = vim.tbl_flatten({ args, "--java-home", fargs.java_home })
        end
        args = vim.tbl_flatten({ args, project .. "/testOnly" })
    else
        error("Should never happen...", vim.log.levels.ERROR)
    end
    return args
end

return M
