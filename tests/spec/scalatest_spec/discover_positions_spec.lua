local scala = require("neotest-scala")
local async = require("neotest-busted.async")
local client = require("neotest.client")({
    require("neotest-scala")({
        framework = "scalatest",
        runner = "bloop",
    }),
})
describe("Basic scenarios", function()
    describe("Scala 2.x", function()
        it(
            "should find positions for AnyFunSuite",
            async(function()
                -- GIVEN
                local file_path = vim.env.TEST_DATA_DIR
                    .. "/scalatest/projects/scala2/src/test/scala/scalatest/basic/SetSuite.scala"

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
                assert.array(list[2]).has.no.holes(2)
                assert.are_equal(
                    "scala.scalatest.basic.SetSuite::Invoking head on an empty Set should produce NoSuchElementException",
                    list[2][3][1].id
                )
            end)
        )
        it(
            "should find positions for AnyWordSpec",
            async(function()
                -- GIVEN
                local file_path = vim.env.TEST_DATA_DIR
                    .. "/scalatest/projects/scala2/src/test/scala/scalatest/basic/WordSpec.scala"

                -- WHEN
                local tree = scala.discover_positions(file_path)
                local list = tree:to_list()

                -- THEN
                assert.array(list).has.no.holes(2)
                assert.are.same(list[1], {
                    id = file_path,
                    name = "WordSpec.scala",
                    path = file_path,
                    range = { 0, 0, 20, 0 },
                    type = "file",
                })
                assert.array(list[2]).has.no.holes(2)
                assert.are_equal(
                    "scala.scalatest.basic.WordSpec::A Set empty produce NoSuchElementException when head is invoked",
                    list[2][2][2][3][1].id
                )
            end)
        )
    end)
end)
