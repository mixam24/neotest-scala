local M = {}

local tresitter = require("neotest.lib.treesitter")

---Retrieves scala package identifiers from the given file
---@param path string: directory or file path where to search for package names
---@return table: list of packages found
function M.discover_packages(path)
    local query = [[
           ; -- Query --
           (package_clause
            name: (package_identifier) @test.name
           ) @test.definition
           ]]
    local packages = {}
    ---@diagnostic disable-next-line: missing-fields
    local tree = tresitter.parse_positions(path, query, { nested_tests = true, require_namespaces = false })
    local i = 0
    for _, child in tree:iter_nodes() do
        local data = child:data()
        if data.type == "test" then
            i = i + 1
            packages[data.path] = { data.name }
        elseif i > 1 then
            error(string.format("More than one package name found in: '%s'", data.path), vim.log.levels.ERROR)
        end
    end
    return packages
end

return M
