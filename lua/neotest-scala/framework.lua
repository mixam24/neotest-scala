local M = {}

---Returns a framework class.
---@param framework string
---@return neotest-scala.Framework|nil
function M.get_framework_class(framework)
    local module
    if framework == "utest" then
        module = require("neotest-scala.utest")
    elseif framework == "munit" then
        module = require("neotest-scala.munit")
    elseif framework == "scalatest" then
        module = require("neotest-scala.scalatest")
    end
    return module
end

return M
