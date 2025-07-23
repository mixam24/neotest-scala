local failed = require("neotest-scala.munit.results.failed")

describe("Failed helper functions scenarios", function()
    it("should process results file and return statuses", function()
        -- GIVEN
        local line =
            "[90m    at [0m[90mmunit.FunSuite.assert[0m[90m([0m[90mFunSuite.scala[0m:[90m11[0m[90m)[0m"

        -- WHEN
        local result = failed.cleaned_trace_line(line)

        -- THEN
        assert.are(result)
        assert.are_same(
            result,
            "    at munit.FunSuite.assert(FunSuite.scala:11)",
            "Stack trace is not cleaned properly!"
        )
    end)
end)
