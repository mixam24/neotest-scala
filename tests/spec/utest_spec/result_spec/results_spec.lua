local types = require("neotest.types")
local async = require("neotest-busted.async")
local scala = require("neotest-scala")({
    framework = "utest",
    runner = "bloop",
})
describe("Basic scenarios", function()
    it(
        "should process results file and return statuses",
        async(function()
            -- GIVEN
            local file_path = vim.env.TEST_DATA_DIR .. "/utest/results/scala2.log"

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
                types.Tree.from_list({
                    {
                        id = "neotest.scala.basic.HelloTests::test1",
                        name = "test1",
                        path = "path/to/the/HelloTests.scala",
                        range = { 12, 6, 16, 7 },
                        type = "test",
                    },
                    {
                        id = "neotest.scala.basic.HelloTests::test2",
                        name = "test1",
                        path = "path/to/the/HelloTests.scala",
                        range = { 12, 6, 16, 7 },
                        type = "test",
                    },
                    {
                        id = "neotest.scala.basic.HelloTests::test3",
                        name = "test1",
                        path = "path/to/the/HelloTests.scala",
                        range = { 12, 6, 16, 7 },
                        type = "test",
                    },
                }, function(_)
                    return "neotest.scala.basic.BasicSuite::Invoking head on an empty Set should produce NoSuchElementException"
                end)
            )

            -- THEN
            local tests = {}
            for key, _ in pairs(results) do
                table.insert(tests, key)
            end
            assert.array(tests).has.no.holes(3)
            assert.same(results["neotest.scala.basic.HelloTests::test1"].status, "failed")
            --- TODO: check the line where test failed...
        end)
    )
end)
