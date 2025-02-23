local Path = require("plenary.path")
local lib = require("neotest.lib")
local fw = require("neotest-scala.framework")
local utils = require("neotest-scala.utils")
local types = require("neotest.types")

---@type neotest.Adapter
local ScalaNeotestAdapter = { name = "neotest-scala" }

ScalaNeotestAdapter.root = lib.files.match_root_pattern("build.sbt")

---@async
---@param file_path string
---@return boolean
function ScalaNeotestAdapter.is_test_file(file_path)
    if not vim.endswith(file_path, ".scala") then
        return false
    end
    local elems = vim.split(file_path, Path.path.sep)
    local file_name = string.lower(elems[#elems])
    local patterns = { "test", "spec", "suite" }
    for _, pattern in ipairs(patterns) do
        if string.find(file_name, pattern) then
            return true
        end
    end
    return false
end

function ScalaNeotestAdapter.filter_dir(_, _, _)
    return true
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

local function get_match_type(captured_nodes)
    if captured_nodes["test.name"] then
        return "test"
    end
    if captured_nodes["namespace.name"] then
        return "namespace"
    end
end

local function build_position(file_path, source, captured_nodes)
    local match_type = get_match_type(captured_nodes)
    if match_type then
        local test_name = captured_nodes[match_type .. ".name"]
        local name
        name = vim.treesitter.get_node_text(test_name, source)
        if test_name:type() == "string" then
            -- TODO: in future we may want to handle more cases...
            name = name:gsub('^"(.*)"$', "%1")
        end
        local func_name
        if match_type == "test" then
            func_name = vim.treesitter.get_node_text(captured_nodes[match_type .. ".func_name"], source)
        end
        local definition = captured_nodes[match_type .. ".definition"]

        return {
            type = match_type,
            path = file_path,
            name = name,
            range = { definition:range() },
            definition_type = definition:type(),
            func_name = func_name,
        }
    end
end
---@async
---@return neotest.Tree | nil
function ScalaNeotestAdapter.discover_positions(path)
    local query = [[
    ; -- Namespaces --
    ; Matches: `object 'Name' ...`
	  (object_definition
	   name: (identifier) @namespace.name)
	   @namespace.definition

    ; Matches: `class 'Name' ...`
    (class_definition
    name: (identifier) @namespace.name)
    @namespace.definition

    ; -- Tests --
    ; Matches: test('name') {...}
    ((call_expression
      function: (call_expression
      function: (identifier) @test.func_name (#match? @test.func_name "test")
      arguments: (arguments (string) @test.name))
    )) @test.definition

    ; Matches: `"name" should / "name" when`
    ((infix_expression
      left: (string) @test.name
      operator: (identifier) @test.func_name (#any-of? @test.func_name "should" "when")
      right: (block)
    )) @test.definition

    ; Matches: `"name" in`
    ((infix_expression
      left: (string) @test.name
      operator: (identifier) @test.func_name (#eq? @test.func_name "in")
      right: (block)
    )) @test.definition
    ]]
    return lib.treesitter.parse_positions(
        path,
        query,
        { nested_tests = true, require_namespaces = true, build_position = build_position }
    )
end

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

local function get_args()
    return {}
end

local function get_framework()
    -- TODO: Automatically detect framework based on build.sbt
    return "utest"
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
    local root = ScalaNeotestAdapter.root(path)
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
        local root = ScalaNeotestAdapter.root(position.path)
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
function ScalaNeotestAdapter.build_spec(args)
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

---Extract results from the test output.
---@param tree neotest.Tree
---@param test_results table<string, string>
---@param match_func nil|fun(test_results: table<string, string>, position_id :string):string|nil
---@return table<string, neotest.Result>
local function get_results(tree, test_results, match_func)
    local no_results = vim.tbl_isempty(test_results)
    local results = {}
    local framework = fw.get_framework_class(get_framework())
    local events = framework.get_test_results(test_results)
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
---@param result neotest.StrategyResult
---@param tree neotest.Tree
---@return table<string, neotest.Result>
function ScalaNeotestAdapter.results(_, result, tree)
    local success, lines = pcall(lib.files.read_lines, result.output)
    local framework = fw.get_framework_class(get_framework())
    if not success or not framework then
        return {}
    end
    for _, child in tree:iter_nodes() do
        local data = child:data()
        if data.type ~= "test" then
            print(vim.inspect(data))
        end
    end
    local test_results = framework.get_test_results(lines)
    return get_results(tree, test_results, framework.match_func)
end

local is_callable = function(obj)
    return type(obj) == "function" or (type(obj) == "table" and obj.__call)
end

setmetatable(ScalaNeotestAdapter, {
    __call = function(_, opts)
        if is_callable(opts.args) then
            get_args = opts.args
        elseif opts.args then
            get_args = function()
                return opts.args
            end
        end
        if is_callable(opts.runner) then
            get_runner = opts.runner
        elseif opts.runner then
            get_runner = function()
                return opts.runner
            end
        end
        if is_callable(opts.framework) then
            get_framework = opts.framework
        elseif opts.framework then
            get_framework = function()
                return opts.framework
            end
        end
        return ScalaNeotestAdapter
    end,
})

return ScalaNeotestAdapter
