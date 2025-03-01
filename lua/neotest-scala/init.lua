local Path = require("plenary.path")
local lib = require("neotest.lib")

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

---@async
---@param result neotest.StrategyResult
---@param tree neotest.Tree
---@return table<string, neotest.Result>
function ScalaNeotestAdapter.results(spec, result, tree)
    local framework_name = ScalaNeotestAdapter.framework
    local impl
    if framework_name == "utest" then
        impl = require("neotest-scala.utest.results")
    elseif framework_name == "munit" then
        impl = require("neotest-scala.munit.results")
    elseif framework_name == "scalatest" then
        impl = require("neotest-scala.scalatest.results")
    end
    for _, child in tree:iter_nodes() do
        local data = child:data()
        if data.type ~= "test" then
            print(vim.inspect(data))
        end
    end
    return impl(spec, result, tree)
end

setmetatable(ScalaNeotestAdapter, {
    __call = function(_, opts)
        if not opts.framework then
            error("'framework' value is not defined in the adapter config!", vim.log.levels.ERROR)
        end
        if not opts.runner then
            error("'runner' value is not defined in the adapter config!", vim.log.levels.ERROR)
        end
        if not opts.runner == "bloop" and not opts.runner == "sbt" then
            error("'runner' value provided is not supported. Supported values: 'sbt', 'bloop'", vim.log.levels.ERROR)
        end
        if not opts.framework == "munit" and not opts.framework == "utest" and not opts.framework == "scalatest" then
            error(
                "'framework' value provided is not supported. Supported values: 'munit', 'utest', 'scalatest'",
                vim.log.levels.ERROR
            )
        end
        --- TODO: let's just merge tables based on the framework value and pass runner and args to the implementation...
        ScalaNeotestAdapter.framework = opts.framework
        ScalaNeotestAdapter.runner = opts.runner
        ScalaNeotestAdapter.args = opts.args or {}
        return ScalaNeotestAdapter
    end,
})

---@type neotest.Adapter
return ScalaNeotestAdapter
