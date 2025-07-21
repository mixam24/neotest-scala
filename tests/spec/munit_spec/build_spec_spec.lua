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
                    name = "WordSpec.scala",
                    path = "path/to/the/WordSpec.scala",
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
