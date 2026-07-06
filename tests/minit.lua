#!/usr/bin/env -S nvim -l

vim.env.LAZY_STDPATH = ".tests"
vim.env.TEST_DATA_DIR = vim.fn.getcwd() .. "/tests/data"
load(vim.fn.system("curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"))()

-- Setup lazy.nvim
local minit = require("lazy.minit")
local opts = minit.busted.setup({
    spec = {
        "LazyVim/starter",
        "lunarmodules/luacov",
        "williamboman/mason-lspconfig.nvim",
        "williamboman/mason.nvim",
        "nvim-neotest/nvim-nio",
        "nvim-lua/plenary.nvim",
        {
            "nvim-neotest/neotest",
            lazy = false,
            dependencies = {
                "MisanthropicBit/neotest-busted",
                {
                    "neovim-treesitter/nvim-treesitter",
                    --- NOTE: https://github.com/neovim-treesitter/nvim-treesitter/tree/main?tab=readme-ov-file#requirements
                    branch = "main",
                    lazy = false,
                    build = function()
                        vim.system({ "npm", "install", "-g", "tree-sitter-cli" }):wait()
                    end,
                    dependencies = { "neovim-treesitter/treesitter-parser-registry" },
                    main = "nvim-treesitter",
                    config = function(plugin, _)
                        require(plugin.main).install({ "scala" }, {}):pwait()
                        require(plugin.main).setup({})
                        vim.print(require(plugin.main).status())
                    end,
                },
            },
        },
    },
    headless = {
        -- show the output from process commands like git
        process = true,
        -- show log messages
        log = true,
        -- show task start/end
        task = true,
        -- use ansi colors
        colors = false,
    },
    performance = {
        reset_packpath = false,
        rtp = {
            --- NOTE: otherwise treesitter parser for scala is not visible right after installation
            reset = false,
        },
    },
    rocks = {
        enabled = true,
        server = "https://lux.lumen-labs.org/rocks-binaries/",
    },
})
minit.setup(opts)
