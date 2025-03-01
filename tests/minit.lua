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
        "nvim-treesitter/nvim-treesitter",
        "nvim-neotest/nvim-nio",
        "nvim-lua/plenary.nvim",
        "nvim-neotest/neotest",
        "MisanthropicBit/neotest-busted",
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
})
minit.setup(opts)
