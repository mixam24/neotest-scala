local scala = require("neotest-scala")
local async = require("neotest-busted.async")
local client = require("neotest.client")({
    require("neotest-scala")({
        framework = "scalatest",
        runner = "bloop",
    }),
})
describe("Scala 2 scenarios", function()
    describe("Basic scenarios", function()
        describe("test discovery", function()
            it(
                "should find positions for AnyFunSuite",
                async(function()
                    -- GIVEN
                    local file_path = vim.env.TEST_DATA_DIR .. "/scala2/src/test/scala/scalatest/basic/SetSuite.scala"

                    -- WHEN
                    local tree = scala.discover_positions(file_path)
                    local list = tree:to_list()

                    -- THEN
                    assert.array(list).has.no.holes(2)
                    assert.are.same(list[1], {
                        id = file_path,
                        name = "SetSuite.scala",
                        path = file_path,
                        range = { 0, 0, 16, 0 },
                        type = "file",
                    })
                    assert.array(list[2]).has.no.holes(5)
                end)
            )
        end)
    end)
end)
