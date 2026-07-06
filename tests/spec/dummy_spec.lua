local async = require("neotest-busted.async")
describe("Dummy", function()
    it(
        "Dummy",
        async(function()
            assert.are_nil(nil, "Result is not nil")
        end)
    )
end)
