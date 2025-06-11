local types = require("neotest.types")
local bloop = require("neotest-scala")({
    framework = "scalatest",
    runner = "bloop",
})
local async = require("neotest-busted.async")

before_each(function()
    local common = require("neotest-scala.common.build_spec")
    ---@diagnostic disable-next-line duplicate-set-field
    common.get_project_name = function()
        return "project"
    end
    package.loaded["neotest-scala.common.build_spec"] = common
end)

after_each(function()
    package.loaded["neotest-scala.common.build_spec"] = nil
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
        "Emit command when root points to a test scenario",
        async(function()
            -- GIVEN

            local tree = types.Tree.from_list({
                {
                    id = "neotest.scala.basic.WordSpec",
                    name = "WordSpec",
                    path = "path/to/the/WordSpec.scala",
                    range = { 4, 0, 22, 1 },
                    type = "namespace",
                },
            }, function(_)
                return "neotest.scala.basic.WordSpec"
            end)

            -- WHEN
            local result = bloop.build_spec({
                tree = tree,
                extra_args = {},
                strategy = "integrated",
            })

            -- THEN
            assert.are(result, "Result is not nil")
            -- TODO: perform actual assertion...
        end)
    )
    it("Emit command when root point to a test suite", async(function() end))
end)
