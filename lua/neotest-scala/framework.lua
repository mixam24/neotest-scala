local M = {}

---Returns a framework class.
---@param framework string
---@return neotest-scala.Framework|nil
function M.get_framework_class(framework)
    local module
    if framework == "utest" then
        module = require("neotest-scala.frameworks.utest")
    elseif framework == "munit" then
        module = require("neotest-scala.frameworks.munit")
    elseif framework == "scalatest" then
        module = require("neotest-scala.frameworks.scalatest")
    end
    return module
end

return M
