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
            local file_path = vim.env.TEST_DATA_DIR .. "/utest/results/scala2-bloop.log"

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
                        id = "neotest.scala.basic.BasicSuite",
                        name = "BasicSuite",
                        path = "path/to/the/BasicSuite.scala",
                        range = { 12, 6, 16, 7 },
                        type = "namespace",
                    },
                    {
                        {
                            id = "neotest.scala.basic.BasicSuite::An empty Set should have size 0",
                            name = "test1",
                            path = "path/to/the/BasicSuite.scala",
                            range = { 12, 6, 16, 7 },
                            type = "test",
                        },
                        {
                            id = "neotest.scala.basic.BasicSuite::Invoking head on an empty Set should produce NoSuchElementException",
                            name = "test1",
                            path = "path/to/the/BasicSuite.scala",
                            range = { 12, 6, 16, 7 },
                            type = "test",
                        },
                        {
                            id = "neotest.scala.basic.BasicSuite::This one will always fail",
                            name = "test1",
                            path = "path/to/the/BasicSuite.scala",
                            range = { 12, 6, 16, 7 },
                            type = "test",
                        },
                        {
                            id = "neotest.scala.basic.BasicSuite::Calling a function that throw NotImplemented",
                            name = "test1",
                            path = "path/to/the/BasicSuite.scala",
                            range = { 12, 6, 16, 7 },
                            type = "test",
                        },
                        {
                            id = "neotest.scala.basic.BasicSuite::Calling a nested function that throw NotImplemented",
                            name = "test1",
                            path = "path/to/the/BasicSuite.scala",
                            range = { 12, 6, 16, 7 },
                            type = "test",
                        },
                        {
                            id = "neotest.scala.basic.BasicSuite::Calling a function that calls one in another object",
                            name = "test1",
                            path = "path/to/the/BasicSuite.scala",
                            range = { 12, 6, 16, 7 },
                            type = "test",
                        },
                        {
                            id = "neotest.scala.basic.BasicSuite::Calling a helper function that throws",
                            name = "test1",
                            path = "path/to/the/BasicSuite.scala",
                            range = { 12, 6, 16, 7 },
                            type = "test",
                        },
                    },
                }, function(_)
                    return "neotest.scala.basic.BasicSuite"
                end)
            )

            -- THEN
            local tests = {}
            for key, _ in pairs(results) do
                table.insert(tests, key)
            end
            assert.array(tests).has.no.holes(3)
            assert.same(results["neotest.scala.basic.BasicSuite::This one will always fail"].status, "failed")
            assert.same(results["neotest.scala.basic.BasicSuite::This one will always fail"].errors[1].line, 21)
        end)
    )
end)
