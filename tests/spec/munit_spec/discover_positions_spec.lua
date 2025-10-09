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
                range = { 0, 0, 66, 0 },
                type = "file",
            })
            assert.array(list[2]).has.no.holes(11)
            assert.are_equal("neotest.basic.BasicSuite::An empty Set should have size 0", list[2][2][1].id)
            --- position with fail mark
            assert.are_equal(
                "neotest.basic.BasicSuite::Invoking head on an empty Set should produce NoSuchElementException",
                list[2][3][1].id
            )
            --- position with pending mark with comment
            assert.are_equal("neotest.basic.BasicSuite::Not ready yet test", list[2][9][1].id)
            --- position with tag
            assert.are_equal("neotest.basic.BasicSuite::Some test to re-run", list[2][10][1].id)
            --- position with flaky mark
            assert.are_equal("neotest.basic.BasicSuite::Some flaky test", list[2][11][1].id)
        end)
    )
end)
