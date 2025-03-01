local treesitter = require("neotest.lib.treesitter")

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
return function(path)
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
    return treesitter.parse_positions(
        path,
        query,
        { nested_tests = true, require_namespaces = true, build_position = build_position }
    )
end
