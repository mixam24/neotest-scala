local scala = require("neotest-scala")({
    framework = "munit",
    runner = "bloop",
})
local async = require("neotest-busted.async")
describe("Basic scenarios", function()
    it(
        "should find positions for FunSuite",
        async(function()
            -- GIVEN
            local file_path = vim.env.TEST_DATA_DIR
                .. "/munit/projects/scala2/src/test/scala/munit/basic/BasicSuite.scala"

            -- WHEN
            local tree = scala.discover_positions(file_path)
            local list = tree:to_list()

            -- THEN
            assert.array(list).has.no.holes(2)
            assert.are.same(list[1], {
                id = file_path,
                name = "BasicSuite.scala",
                path = file_path,
                range = { 0, 0, 34, 0 },
                type = "file",
            })
            assert.array(list[2]).has.no.holes(7)
            assert.are_equal("neotest.basic.BasicSuite::An empty Set should have size 0", list[2][2][1].id)
        end)
    )
end)
