local utils = require("neotest-scala.utils")
local tresitter = require("neotest.lib.treesitter")
local M = {}

TEST_PASSED = "passed" -- the test passed
TEST_FAILED = "failed" -- the test failed

---@class neotest-scala.Framework
---@field build_command fun(runner: string, project: string, tree: neotest.Tree, name: string, extra_args: table|string): string[]
---@field get_test_results fun(output_lines: string[]): table<string, neotest.Result>
---@field match_func nil|fun(test_results: table<string, string>, position_id :string):string|nil

--- Strip ainsi characters from the string, leaving the rest of the string intact.
---@param s string
---@return string
local function strip_ainsi_chars(s)
    local v = s:gsub("\x1b%[%d+;%d+;%d+;%d+;%d+m", "")
        :gsub("\x1b%[%d+;%d+;%d+;%d+m", "")
        :gsub("\x1b%[%d+;%d+;%d+m", "")
        :gsub("\x1b%[%d+;%d+m", "")
        :gsub("\x1b%[%d+m", "")
    return v
end

--- Strip sbt info logging prefix from string.
---@param s string
---@return string
local function strip_sbt_info_prefix(s)
    local v = s:gsub("^%[info%] ", "")
    return v
end

---@param project string
---@param runner string
---@param test_path string|nil
---@param extra_args table|string
---@return string[]
local function build_command_with_test_path(project, runner, test_path, extra_args)
    if runner == "bloop" then
        local full_test_path
        if not test_path then
            full_test_path = {}
        else
            full_test_path = { "--", test_path }
        end
        return vim.tbl_flatten({ "bloop", "test", extra_args, project, full_test_path })
    end
    if not test_path then
        return vim.tbl_flatten({ "sbt", extra_args, project .. "/test" })
    end
    -- TODO: Run sbt with colors, but figuoure wich ainsi sequence need to be matched.
    return vim.tbl_flatten({
        "sbt",
        "--no-colors",
        extra_args,
        project .. "/testOnly -- " .. '"' .. test_path .. '"',
    })
end

---@return neotest-scala.Framework
local function utest_framework()
    -- Builds a test path from the current position in the tree.
    ---@param tree neotest.Tree
    ---@param name string
    ---@return string|nil
    local function build_test_path(tree, name)
        local parent_tree = tree:parent()
        local type = tree:data().type
        if parent_tree and parent_tree:data().type == "namespace" then
            local package = utils.get_package_name(parent_tree:data().path)
            local parent_name = parent_tree:data().name
            return package .. parent_name .. "." .. name
        end
        if parent_tree and parent_tree:data().type == "test" then
            local parent_pos = parent_tree:data()
            return build_test_path(parent_tree, utils.get_position_name(parent_pos)) .. "." .. name
        end
        if type == "namespace" then
            local package = utils.get_package_name(tree:data().path)
            if not package then
                return nil
            end
            return package .. name
        end
        if type == "file" then
            local test_suites = {}
            for _, child in tree:iter_nodes() do
                if child:data().type == "namespace" then
                    table.insert(test_suites, child:data().name)
                end
            end
            if test_suites then
                local package = utils.get_package_name(tree:data().path)
                return package .. "{" .. table.concat(test_suites, ",") .. "}"
            end
        end
        if type == "dir" then
            local packages = {}
            local visited = {}
            for _, child in tree:iter_nodes() do
                if child:data().type == "namespace" then
                    local package = utils.get_package_name(child:data().path)
                    if package and not visited[package] then
                        table.insert(packages, package:sub(1, -2))
                        visited[package] = true
                    end
                end
            end
            if packages then
                return "{" .. table.concat(packages, ",") .. "}"
            end
        end
        return nil
    end

    --- Builds a command for running tests for the framework.
    ---@param runner string
    ---@param project string
    ---@param tree neotest.Tree
    ---@param name string
    ---@param extra_args table|string
    ---@return string[]
    local function build_command(runner, project, tree, name, extra_args)
        local test_path = build_test_path(tree, name)
        return build_command_with_test_path(project, runner, test_path, extra_args)
    end

    ---Get test ID from the test line output.
    ---@param output string
    ---@return string
    local function get_test_id(output)
        local words = vim.split(output, " ", { trimempty = true })
        -- Strip the test success indicator prefix and time taken in ms suffix.
        table.remove(words, 1)
        table.remove(words)
        return table.concat(words, " ")
    end

    -- Get test results from the test output.
    ---@param output_lines string[]
    ---@return table<string, string>
    local function get_test_results(output_lines)
        local test_results = {}
        for _, line in ipairs(output_lines) do
            line = strip_ainsi_chars(line)
            if vim.startswith(line, "+") then
                local test_id = get_test_id(line)
                test_results[test_id] = TEST_PASSED
            elseif vim.startswith(line, "X") then
                local test_id = get_test_id(line)
                test_results[test_id] = TEST_FAILED
            end
        end
        return test_results
    end

    return {
        get_test_results = get_test_results,
        build_command = build_command,
    }
end

---@return neotest-scala.Framework
local function munit_framework()
    -- Builds a test path from the current position in the tree.
    ---@param tree neotest.Tree
    ---@param name string
    ---@return string|nil
    local function build_test_path(tree, name)
        local parent_tree = tree:parent()
        local type = tree:data().type
        if parent_tree and parent_tree:data().type == "namespace" then
            local package = utils.get_package_name(parent_tree:data().path)
            local parent_name = parent_tree:data().name
            return package .. parent_name .. "." .. name
        end
        if parent_tree and parent_tree:data().type == "test" then
            local parent_pos = parent_tree:data()
            return build_test_path(parent_tree, utils.get_position_name(parent_pos)) .. "." .. name
        end
        if type == "namespace" then
            local package = utils.get_package_name(tree:data().path)
            if not package then
                return nil
            end
            return package .. name .. ".*"
        end
        if type == "file" then
            local test_suites = {}
            for _, child in tree:iter_nodes() do
                if child:data().type == "namespace" then
                    table.insert(test_suites, child:data().name)
                end
            end
            if test_suites then
                local package = utils.get_package_name(tree:data().path)
                return package .. "*"
            end
        end
        if type == "dir" then
            return "*"
        end
        return nil
    end

    --- Builds a command for running tests for the framework.
    ---@param runner string
    ---@param project string
    ---@param tree neotest.Tree
    ---@param name string
    ---@param extra_args table|string
    ---@return string[]
    local function build_command(runner, project, tree, name, extra_args)
        local test_path = build_test_path(tree, name)
        return build_command_with_test_path(project, runner, test_path, extra_args)
    end

    ---Get test ID from the test line output.
    ---@param output string
    ---@return string
    local function get_test_name(output, prefix)
        return output:match("^" .. prefix .. " (.*) %d*%.?%d+s.*") or nil
    end

    ---Get test namespace from the test line output.
    ---@param output string
    ---@return string|nil
    local function get_test_namespace(output)
        return output:match("^([%w%.]+):") or nil
    end

    -- Get test results from the test output.
    ---@param output_lines string[]
    ---@return table<string, string>
    local function get_test_results(output_lines)
        local test_results = {}
        local test_namespace = nil
        for _, line in ipairs(output_lines) do
            line = vim.trim(strip_ainsi_chars(line))
            local current_namespace = get_test_namespace(line)
            if current_namespace and (not test_namespace or test_namespace ~= current_namespace) then
                test_namespace = current_namespace
            end
            if test_namespace and vim.startswith(line, "+") then
                local test_name = get_test_name(line, "+")
                if test_name then
                    local test_id = test_namespace .. "." .. vim.trim(test_name)
                    test_results[test_id] = TEST_PASSED
                end
            elseif test_namespace and vim.startswith(line, "==> X") then
                local test_name = get_test_name(line, "==> X")
                if test_name then
                    test_results[vim.trim(test_name)] = TEST_FAILED
                end
            end
        end
        return test_results
    end

    return {
        get_test_results = get_test_results,
        build_command = build_command,
    }
end

---@return neotest-scala.Framework
local function scalatest_framework()
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
        local tree = tresitter.parse_positions(file_path, query, { nested_tests = true, require_namespaces = false })
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
        local tree = tresitter.parse_positions(file_path, query, { nested_tests = true, require_namespaces = false })
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
            error(
                string.format("Expected to receive a node of type 'file' but got '%s'", node.type, vim.log.levels.ERROR)
            )
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
                    full_test_path = vim.tbl_flatten(full_test_path, { "-z", arguments[1].name })
                end
                print(vim.inspect(full_test_path))
                return vim.tbl_flatten({ "bloop", "test", extra_args, project, full_test_path })
            else
                full_test_path = {}
                for _, arg in pairs(arguments) do
                    full_test_path = vim.tbl_flatten(full_test_path, { "-o", arg.class })
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

    ---Get test ID from the test line output.
    ---@param output string
    ---@return string
    local function get_test_name(output, suffix)
        return output:match("^- (.*)" .. suffix) or nil
    end

    ---Get test namespace from the test line output.
    ---@param output string
    ---@return string|nil
    local function get_test_namespace(output)
        return output:match("^([%w%.]+):") or nil
    end

    ---Check if line represents begining or ending of the section
    ---@param line string: a single line of the test output
    local function check_for_context(line)
        local match
        local sanitized_string = strip_ainsi_chars(line)
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

    return {
        get_test_results = get_test_results,
        build_command = build_command,
        match_func = match_func,
    }
end

---Returns a framework class.
---@param framework string
---@return neotest-scala.Framework|nil
function M.get_framework_class(framework)
    if framework == "utest" then
        return utest_framework()
    elseif framework == "munit" then
        return munit_framework()
    elseif framework == "scalatest" then
        return scalatest_framework()
    end
end

return M
