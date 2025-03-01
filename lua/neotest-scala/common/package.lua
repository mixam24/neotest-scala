local M = {}

local tresitter = require("neotest.lib.treesitter")

---Retrieves scala package identifiers from the given file
---@param file_path string: file path
---@return table: list of packages found
function M.discover_packages(file_path)
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

return M
