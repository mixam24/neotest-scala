local types = require("neotest.types")
local scala = require("neotest-scala")({
    framework = "scalatest",
    runner = "bloop",
})
local async = require("neotest-busted.async")
describe("Basic scenarios", function()
    it(
        "should process results file and return statuses",
        async(function()
            -- GIVEN
            local file_path = vim.env.TEST_DATA_DIR .. "/scalatest/results/scala2.log"

            -- WHEN
            local results = scala.results(
                {
                    command = {},
                    stream = function(_)
                        ---@diagnostic disable-next-line: return-type-mismatch
                        return {}
                    end,
                    context = { results_path = file_path },
                },
                { output = "", code = 0 },
                types.Tree.from_list({}, function(_)
                    return ""
                end)
            )

            -- THEN
            local tests = {}
            for key, _ in pairs(results) do
                table.insert(tests, key)
            end
            assert.array(tests).has.no.holes(6)
            assert.same(results["neotest.scala.basic.SetSuite::This one will always fail"].status, "failed")
        end)
    )
    it(
        "should return valid error messages",
        async(function()
            -- GIVEN
            local file_path = vim.env.TEST_DATA_DIR .. "/scalatest/results/scala2.log"

            -- WHEN
            local results = scala.results(
                {
                    command = {},
                    stream = function(_)
                        ---@diagnostic disable-next-line: return-type-mismatch
                        return {}
                    end,
                    context = { results_path = file_path },
                },
                { output = "", code = 0 },
                types.Tree.from_list({}, function(_)
                    return ""
                end)
            )

            -- THEN
            local tests = {}
            for key, _ in pairs(results) do
                table.insert(tests, key)
            end
            assert.equal(results["neotest.scala.basic.SetSuite::This one will always fail"].errors[1].line, 21)
            assert.equal(
                results["neotest.scala.basic.SetSuite::Calling a function that throw NotImplemented"].errors[1].line,
                24
            )
            assert.equal(
                results["neotest.scala.basic.SetSuite::Calling a nested function that throw NotImplemented"].errors[1].line,
                27
            )
            assert.equal(
                results["neotest.scala.basic.SetSuite::Calling a function that calls one in another object"].errors[1].line,
                30
            )
            assert.equal(
                results["neotest.scala.basic.SetSuite::Calling a helper function that throws"].errors[1].line,
                33
            )
        end)
    )
end)
