#!/usr/bin/env -S nvim -l

vim.env.LAZY_STDPATH = ".tests"
load(vim.fn.system("curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"))()

-- Setup lazy.nvim
local minit = require("lazy.minit")
local opts = minit.busted.setup({
    spec = {
        "LazyVim/starter",
        "williamboman/mason-lspconfig.nvim",
        "williamboman/mason.nvim",
        "nvim-treesitter/nvim-treesitter",
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
