local types = require("neotest.types")
local bloop = require("neotest-scala")({
    framework = "munit",
    runner = "bloop",
})
local sbt = require("neotest-scala")({
    framework = "munit",
    runner = "sbt",
})
local async = require("neotest-busted.async")

before_each(function()
    local common = require("neotest-scala.common.build_spec")
    ---@diagnostic disable-next-line duplicate-set-field
    common.get_project_name = function()
        return "project"
    end
    package.loaded["neotest-scala.common.build_spec"] = common
    local nio = require("nio")
    nio.fn.tempname = function()
        return "tempfile"
    end
    package.loaded["nio"] = nio
end)

describe("Bloop scenarios", function()
    it(
        "Emit nil when root points to a dir",
        async(function()
            -- GIVEN
            local tree = types.Tree.from_list({
                {
                    id = "id",
                    name = "MyDir",
                    path = "path/to/the/MyDir",
                    type = "dir",
                },
            }, function(_)
                return "id"
            end)

            -- WHEN
            local result = bloop.build_spec({
                tree = tree,
                extra_args = {},
                strategy = "integrated",
            })

            -- THEN
            assert.are_nil(result, "Result is not nil")
        end)
    )
    it(
        "Emit nil when root points to a file",
        async(function()
            -- GIVEN
            local tree = types.Tree.from_list({
                {
                    id = "id",
                    name = "BasicSuite.scala",
                    path = "path/to/the/BasicSuite.scala",
                    type = "file",
                },
            }, function(_)
                return "id"
            end)

            -- WHEN
            local result = bloop.build_spec({
                tree = tree,
                extra_args = {},
                strategy = "integrated",
            })

            -- THEN
            assert.are_nil(result, "Result is not nil")
        end)
    )
    it(
        "Emit command when root point to a test suite",
        async(function()
            -- GIVEN
            local tree = types.Tree.from_list({
                {
                    id = "neotest.scala.basic.BasicSuite",
                    name = "BasicSuite",
                    path = "path/to/the/BasicSuite.scala",
                    range = { 4, 0, 22, 1 },
                    type = "namespace",
                },
            }, function(_)
                return "neotest.scala.basic.BasicSuite"
            end)

            -- WHEN
            local result = bloop.build_spec({
                tree = tree,
                extra_args = {},
                strategy = "integrated",
            })

            -- THEN
            assert.are(result, "Result is nil")
            assert.are_same({
                "bloop",
                "test",
                "project",
                "--",
                "neotest.scala.basic.BasicSuite.*",
            }, result.command, "Not what expected as command")
            assert.are_same({}, result.context, "Not what expected as context")
        end)
    )
    it(
        "Emit command when root points to a test scenario",
        async(function()
            -- GIVEN
            local tree = types.Tree.from_list({
                {
                    id = "neotest.scala.basic.BasicSuite::Invoking head on an empty Set should produce NoSuchElementException",
                    name = "Invoking head on an empty Set should produce NoSuchElementException",
                    path = "path/to/the/BasicSuite.scala",
                    range = { 12, 6, 16, 7 },
                    type = "test",
                },
            }, function(_)
                return "neotest.scala.basic.BasicSuite::Invoking head on an empty Set should produce NoSuchElementException"
            end)

            -- WHEN
            local result = bloop.build_spec({
                tree = tree,
                extra_args = {},
                strategy = "integrated",
            })

            -- THEN
            assert.are(result, "Result is nil")
            assert.are_same({
                "bloop",
                "test",
                "project",
                "--",
                "neotest.scala.basic.BasicSuite.Invoking head on an empty Set should produce NoSuchElementException",
            }, result.command, "Not what expected as command")
            assert.are_same({}, result.context, "Not what expected as context")
        end)
    )
end)
describe("Sbt scenarios", function()
    it(
        "Emit nil when root points to a dir",
        async(function()
            -- GIVEN
            local tree = types.Tree.from_list({
                {
                    id = "id",
                    name = "MyDir",
                    path = "path/to/the/MyDir",
                    type = "dir",
                },
            }, function(_)
                return "id"
            end)

            -- WHEN
            local result = sbt.build_spec({
                tree = tree,
                extra_args = {},
                strategy = "integrated",
            })

            -- THEN
            assert.are_nil(result, "Result is not nil")
        end)
    )
    it(
        "Emit nil when root points to a file",
        async(function()
            -- GIVEN
            local tree = types.Tree.from_list({
                {
                    id = "id",
                    name = "WordSpec.scala",
                    path = "path/to/the/WordSpec.scala",
                    type = "file",
                },
            }, function(_)
                return "id"
            end)

            -- WHEN
            local result = sbt.build_spec({
                tree = tree,
                extra_args = {},
                strategy = "integrated",
            })

            -- THEN
            assert.are_nil(result, "Result is not nil")
        end)
    )
    it(
        "Emit command when root point to a test suite",
        async(function()
            --- TODO: add test
        end)
    )
    it(
        "Emit command when root points to a test scenario",
        async(function()
            --- TODO: add test
        end)
    )
end)
