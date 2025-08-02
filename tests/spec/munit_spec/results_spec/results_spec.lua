local types = require("neotest.types")
local async = require("neotest-busted.async")
local scala = require("neotest-scala")({
    framework = "munit",
    runner = "bloop",
})
describe("Basic scenarios", function()
    it(
        "should process results file and return statuses",
        async(function()
            -- GIVEN
            local file_path = vim.env.TEST_DATA_DIR .. "/munit/results/scala2-bloop.log"

            -- WHEN
            local results = scala.results(
                {
                    command = {},
                    stream = function(_)
                        ---@diagnostic disable-next-line: return-type-mismatch
                        return {}
                    end,
                    context = {},
                },
                { output = file_path, code = 0 },
                types.Tree.from_list({}, function(_)
                    return ""
                end)
            )

            -- THEN
            local tests = {}
            for key, _ in pairs(results) do
                table.insert(tests, key)
            end
            assert.array(tests).has.no.holes(7)
            assert.same(results["neotest.basic.BasicSuite::This one will always fail"].status, "failed")
            --- TODO: check the line where test failed...
        end)
    )
end)
