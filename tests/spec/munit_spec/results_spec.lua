local lib = require("neotest.lib")
local async = require("neotest-busted.async")
describe("Basic scenarios", function()
    it(
        "can find sucessfull tests in the tests output",
        async(function()
            -- GIVEN
            local file_path = vim.env.TEST_DATA_DIR .. "/munit/results/scala2.log"
            local lines = lib.files.read_lines(file_path)
            --- GREEN = "\u001B[32m";
            --- NORMAL = "\u001B[0m";
            --- c(s, color) === return color + s + NORMAL
            --- Success === c("  + ", SUCCESS1)

            --- Building blocks
            local green = vim.lpeg.P("\x1B[32m")
            local faint = vim.lpeg.P("\x1B[90m")
            local light_red = vim.lpeg.P("\x1B[91m")
            local normal = vim.lpeg.P("\x1B[0m")
            local colors = green + faint + light_red + normal
            local alpha_numeric = vim.lpeg.R("az", "AZ", "09")
            local numeric = vim.lpeg.R("09")
            local dot = vim.lpeg.S(".")
            local spaces = vim.lpeg.P(" ") ^ 1
            local any = vim.lpeg.P(1)

            local test_suite_name = vim.lpeg.Cg((alpha_numeric ^ 1 * dot ^ 0) ^ 1, "suite_name")
            local test_name = vim.lpeg.Cg((any - colors) ^ 0, "test_name")
            local duration = vim.lpeg.Cg(numeric ^ 1 * dot ^ 0 * numeric ^ 0, "duration") * vim.lpeg.P("s")

            local failed_test_name = light_red
                * test_suite_name
                * normal
                * (vim.lpeg.P(".") * light_red * test_name * normal) ^ 0

            local test_suite_started = vim.lpeg.Ct(green * test_suite_name * vim.lpeg.P(":") * normal)
            local test_finished = vim.lpeg.Ct(
                green * vim.lpeg.P("  + ") * normal * green * test_name * normal * spaces * faint * duration * normal
            )
            local test_failure = vim.lpeg.Ct(
                light_red
                    * vim.lpeg.P("==> X ")
                    * normal
                    * failed_test_name
                    * spaces
                    * faint
                    * duration
                    * normal
                    * any ^ 0
            )

            for _, line in pairs(lines) do
                local test_suite_started_match = vim.lpeg.match(test_suite_started, line)
                if test_suite_started_match ~= nil then
                    print(test_suite_started_match.value)
                end
                local test_finished_match = vim.lpeg.match(test_finished, line)
                if test_finished_match ~= nil then
                    print(test_finished_match.value)
                end
                local test_failure_match = vim.lpeg.match(test_failure, line)
                if test_failure_match ~= nil then
                    print(test_failure_match.value)
                end
            end
        end)
    )
end)
