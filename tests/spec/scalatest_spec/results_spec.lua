local types = require("neotest.types")
local scala = require("neotest-scala")({
    framework = "scalatest",
    runner = "bloop",
})
local async = require("neotest-busted.async")
local client = require("neotest.client")({
    require("neotest-scala")({
        framework = "scalatest",
        runner = "bloop",
    }),
})
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
            assert.same(results["scala.scalatest.basic.SetSuite::This one will always fail"].status, "failed")
        end)
    )
end)
