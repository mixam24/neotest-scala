local M = {}

---Returns a framework class.
---@param framework string
---@return neotest-scala.Framework|nil
function M.get_framework_class(framework)
    if framework == "utest" then
        return require("neotest-scala.frameworks.utest")
    elseif framework == "munit" then
        return require("neotest-scala.frameworks.munit")
    elseif framework == "scalatest" then
        return require("neotest-scala.frameworks.scalatest")
    end
end

return M
