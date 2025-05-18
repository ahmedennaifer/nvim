
-- Enhanced single file Neovim configuration with Oil.nvim and Symbols Outline

-- Set leader key early
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- Basic Neovim settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"
vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
vim.opt.wrap = false
vim.opt.termguicolors = true
vim.opt.cursorline = true
vim.opt.scrolloff = 5
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.pumheight = 10
vim.opt.cmdheight = 1
vim.opt.showmode = false
vim.opt.hlsearch = true
vim.opt.incsearch = true

-- Completely disable LSP diagnostics and warnings
vim.diagnostic.config({
    virtual_text = false,
    signs = false,     -- Disable all signs including error icons
    underline = false, -- Disable underlines
    update_in_insert = false,
    severity_sort = false,
    float = {
        border = "rounded",
        source = "always",
        header = "",
        prefix = "",
    },
})

-- Autocommands
local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Highlight on yank
augroup("YankHighlight", { clear = true })
autocmd("TextYankPost", {
    group = "YankHighlight",
    callback = function()
        vim.highlight.on_yank({ higroup = "IncSearch", timeout = 150 })
    end,
})

-- Remove trailing whitespace on save
autocmd("BufWritePre", {
    pattern = "*",
    command = [[%s/\s\+$//e]],
})

-- Don't auto-comment new lines
autocmd("BufEnter", {
    pattern = "*",
    command = "set fo-=c fo-=r fo-=o",
})

-- Return to last edit position when opening files
autocmd("BufReadPost", {
    pattern = "*",
    command = [[if line("'\"") > 0 && line("'\"") <= line("$") | exe "normal! g'\"" | endif]],
})

-- Create directory when saving a file, if it doesn't exist
autocmd("BufWritePre", {
    group = augroup("auto_create_dir", { clear = true }),
    callback = function(event)
        local file = vim.loop.fs_realpath(event.match) or event.match
        vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
    end,
})

-- Format on save for Python files with Ruff
autocmd("BufWritePre", {
    pattern = "*.py",
    callback = function()
        vim.lsp.buf.format({ timeout_ms = 1000 })
    end,
})

-- Key mappings
local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- General mappings
map("n", "<Esc>", "<cmd>nohlsearch<CR>", opts)
map("n", "<C-h>", "<C-w>h", opts)
map("n", "<C-j>", "<C-w>j", opts)
map("n", "<C-k>", "<C-w>k", opts)
map("n", "<C-l>", "<C-w>l", opts)
map("n", "<leader>w", "<cmd>w<CR>", { desc = "Save" })
map("n", "<leader>q", "<cmd>q<CR>", { desc = "Quit" })
map("n", "<leader>c", "<cmd>bd<CR>", { desc = "Close buffer" })
map("n", "<leader>h", "<cmd>nohlsearch<CR>", { desc = "Clear highlights" })
map("v", "<", "<gv", opts)
map("v", ">", ">gv", opts)
map("i", "jk", "<Esc>", opts)
map("t", "jk", "<C-\\><C-n>", opts)

-- Window resizing
map("n", "<C-Up>", "<cmd>resize -2<CR>", opts)
map("n", "<C-Down>", "<cmd>resize +2<CR>", opts)
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", opts)
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", opts)

-- Move lines up and down
map("n", "<A-j>", "<cmd>m .+1<CR>==", opts)
map("n", "<A-k>", "<cmd>m .-2<CR>==", opts)
map("i", "<A-j>", "<Esc><cmd>m .+1<CR>==gi", opts)
map("i", "<A-k>", "<Esc><cmd>m .-2<CR>==gi", opts)
map("v", "<A-j>", ":m '>+1<CR>gv=gv", opts)
map("v", "<A-k>", ":m '<-2<CR>gv=gv", opts)

-- Oil file explorer mappings
map("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
map("n", "<leader>-", "<CMD>Oil --float<CR>", { desc = "Open file explorer (float)" })

-- LSP Mappings (available after LSP attaches)
local lsp_mappings = function(client, bufnr)
    local lsp_map = function(keys, func, desc)
        vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
    end

    lsp_map("gd", vim.lsp.buf.definition, "Go to Definition")
    lsp_map("gD", vim.lsp.buf.declaration, "Go to Declaration")
    lsp_map("gi", vim.lsp.buf.implementation, "Go to Implementation")
    lsp_map("gr", "<cmd>Telescope lsp_references<cr>", "Go to References")
    lsp_map("K", vim.lsp.buf.hover, "Hover Documentation")
    lsp_map("<leader>rn", vim.lsp.buf.rename, "Rename")
    lsp_map("<leader>ca", vim.lsp.buf.code_action, "Code Action")
    lsp_map("<leader>lf", vim.lsp.buf.format, "Format")
    lsp_map("[d", vim.diagnostic.goto_prev, "Previous Diagnostic")
    lsp_map("]d", vim.diagnostic.goto_next, "Next Diagnostic")
    lsp_map("<leader>ld", "<cmd>Telescope diagnostics<cr>", "Diagnostics")

    -- Highlight references of the word under your cursor
    if client and client.server_capabilities.documentHighlightProvider then
        local highlight_group = augroup('lsp_document_highlight', { clear = true })
        autocmd({ 'CursorHold', 'CursorHoldI' }, {
            group = highlight_group,
            buffer = bufnr,
            callback = vim.lsp.buf.document_highlight,
        })
        autocmd('CursorMoved', {
            group = highlight_group,
            buffer = bufnr,
            callback = vim.lsp.buf.clear_references,
        })
    end
end

-- Plugin specification
local plugins = {
    -- Plugin management and dependencies
    {
        "folke/lazy.nvim",
        version = false
    },

    -- Dependency for many plugins
    { "nvim-lua/plenary.nvim" },
    
    -- Web devicons with high priority
    { 
        "nvim-tree/nvim-web-devicons", 
        lazy = false,
        priority = 1000,
        config = function()
            require("nvim-web-devicons").setup({
                default = true,
            })
        end
    },

    -- SNACKS.NVIM - QoL Collection (with enhanced explorer)
    {
        "folke/snacks.nvim",
        priority = 1000,
        lazy = false,
        keys = {
            -- Explorer and picker
            { "<leader><space>", function() Snacks.picker.smart() end, desc = "Smart Find Files" },
            { "<leader>,", function() Snacks.picker.buffers() end, desc = "Buffers" },
            { "<leader>/", function() Snacks.picker.grep() end, desc = "Live Grep" },
            { "<leader>e", function() Snacks.explorer() end, desc = "Open Explorer" },
            
            -- Other snacks features
            { "<leader>z", function() Snacks.zen() end, desc = "Toggle Zen Mode" },
            { "<leader>Z", function() Snacks.zen.zoom() end, desc = "Toggle Zoom" },
            { "<leader>n", function() Snacks.notifier.show_history() end, desc = "Notification History" },
            { "<leader>un", function() Snacks.notifier.hide() end, desc = "Dismiss All Notifications" },
            { "<leader>bd", function() Snacks.bufdelete() end, desc = "Delete Buffer" },
            { "<leader>gg", function() Snacks.lazygit() end, desc = "Lazygit" },
            { "<leader>gb", function() Snacks.git.blame_line() end, desc = "Git Blame Line" },
            { "<leader>gB", function() Snacks.gitbrowse() end, desc = "Git Browse" },
            { "<leader>gf", function() Snacks.lazygit.log_file() end, desc = "Lazygit Current File History" },
            { "<leader>gl", function() Snacks.lazygit.log() end, desc = "Lazygit Log (cwd)" },
            { "<leader>cR", function() Snacks.rename.rename_file() end, desc = "Rename File" },
            { "<c-/>", function() Snacks.terminal() end, desc = "Toggle Terminal" },
            { "<c-_>", function() Snacks.terminal() end, desc = "which_key_ignore" },
            { "]]", function() Snacks.words.jump(vim.v.count1) end, desc = "Next Reference" },
            { "[[", function() Snacks.words.jump(-vim.v.count1) end, desc = "Prev Reference" },
        },
        init = function()
            vim.api.nvim_create_autocmd("User", {
                pattern = "VeryLazy",
                callback = function()
                    -- Setup some globals for debugging (lazy-loaded)
                    _G.dd = function(...)
                        Snacks.debug.inspect(...)
                    end
                    _G.bt = function()
                        Snacks.debug.backtrace()
                    end
                    vim.print = _G.dd -- Override print to use snacks for `:=` command

                    -- Create some toggle mappings
                    Snacks.toggle.option("spell", { name = "spelling" }):map("<leader>us")
                    Snacks.toggle.option("wrap", { name = "wrap" }):map("<leader>uw")
                    Snacks.toggle.option("relativenumber", { name = "relative number" }):map("<leader>uL")
                    Snacks.toggle.diagnostics():map("<leader>ud")
                    Snacks.toggle.line_number():map("<leader>ul")
                    Snacks.toggle.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map("<leader>uc")
                    Snacks.toggle.treesitter():map("<leader>uT")
                    Snacks.toggle.option("background", { off = "light", on = "dark", name = "dark background" }):map("<leader>ub")
                    Snacks.toggle.inlay_hints():map("<leader>uh")
                end,
            })
        end,
        opts = {
            -- Beautiful startup dashboard
            dashboard = {
                enabled = true,
                width = 60,
                row = nil, -- dashboard position. nil for center
                col = nil, -- dashboard position. nil for center
                pane_gap = 4, -- empty columns between vertical panes
                autokeys = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ", -- autokey sequence
                preset = {
                    pick = nil,
                    keys = {
                        { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.picker.smart()" },
                        { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
                        { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.picker.grep()" },
                        { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.picker.recent()" },
                        { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.picker.files({cwd = vim.fn.stdpath('config')})" },
                        { icon = " ", key = "e", desc = "Explorer", action = ":lua Snacks.explorer()" },
                        { icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy" },
                        { icon = " ", key = "q", desc = "Quit", action = ":qa" },
                    },
                    header = [[
 ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
 ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
 ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
 ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
 ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
 ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
]],
                },
                sections = {
                    { section = "header" },
                    { icon = " ", title = "Keymaps", section = "keys", indent = 2, padding = 1 },
                    { icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = 1 },
                    { section = "startup" },
                },
            },
            -- Snacks Explorer (as alternative to oil for tree view)
            explorer = {
                enabled = true,
                replace_netrw = false, -- Let oil handle directory buffers
                auto_close = false,    -- Keep explorer open when selecting files
                focus = "list",        -- Focus the list when opening
            },
            picker = {
                enabled = true,
                -- Configure sources properly to avoid "No supported finder" error
                sources = {
                    files = {
                        hidden = false,
                        ignored = false,
                        -- Use find command instead of fd to avoid errors
                        cmd = "find",
                        args = { ".", "-type", "f", "-not", "-path", "*/\\.git/*" },
                    },
                    grep = {
                        -- Use ripgrep if available, otherwise grep
                        cmd = vim.fn.executable("rg") == 1 and "rg" or "grep",
                        args = vim.fn.executable("rg") == 1 and {
                            "--color=never",
                            "--no-heading", 
                            "--with-filename",
                            "--line-number",
                            "--column",
                            "--smart-case",
                        } or {
                            "-r",
                            "-n",
                            "-H",
                        },
                        supports_live = vim.fn.executable("rg") == 1,
                    },
                    explorer = {
                        hidden = true,
                        git_status = true,
                        git_untracked = true,
                        follow_file = true,
                        tree = true,
                        auto_close = false,
                        layout = {
                            preset = "sidebar",
                            preview = false,
                        },
                    },
                },
            },
            -- Smooth scrolling
            scroll = {
                enabled = true,
                animate = {
                    duration = { step = 15, total = 250 },
                    easing = "linear",
                },
            },
            -- Beautiful notifications
            notifier = {
                enabled = true,
                timeout = 3000,
                width = { min = 40, max = 0.4 },
                height = { min = 1, max = 0.6 },
                margin = { top = 0, right = 1, bottom = 0 },
                padding = true,
                sort = { "level", "added" },
                level = vim.log.levels.TRACE,
                icons = {
                    error = " ",
                    warn = " ",
                    info = " ",
                    debug = " ",
                    trace = " ",
                },
                style = "compact",
                top_down = true,
            },
            -- Enhanced snacks features
            quickfile = { enabled = true },
            input = { enabled = true },
            bigfile = { enabled = true, notify = true, size = 1.5 * 1024 * 1024 },
            dim = { enabled = false },
            words = { enabled = true },
            terminal = { enabled = true },
            zen = { enabled = true },
            -- Enable scope highlighting (simplified to avoid errors)
            scope = { 
                enabled = true,
                animate = {
                    enabled = false,  -- Disable animations to prevent conflicts
                },
            },
            -- Pretty indent guides (simplified)
            indent = {
                enabled = true,
                animate = {
                    enabled = false,  -- Disable animations to prevent conflicts
                },
                scope = {
                    enabled = true,
                    animate = {
                        enabled = false,
                    },
                },
            },
        },
    },

    -- OIL.NVIM - Edit filesystem like a buffer (REPLACES NVIM-TREE)
    {
        "stevearc/oil.nvim",
        ---@module 'oil'
        ---@type oil.SetupOpts
        dependencies = { 
            "nvim-tree/nvim-web-devicons", -- for pretty icons  
        },
        lazy = false, -- Don't lazy load oil since it replaces netrw
        config = function()
            require("oil").setup({
                -- Oil will take over directory buffers (e.g. `vim .` or `:e src/`)
                default_file_explorer = true,
                -- Id is automatically added at the beginning, and name at the end
                columns = {
                    "icon",
                    -- "permissions",
                    -- "size",
                    -- "mtime",
                },
                -- Buffer-local options to use for oil buffers
                buf_options = {
                    buflisted = false,
                    bufhidden = "hide",
                },
                -- Restore window options when exiting oil buffer
                restore_win_options = true,
                -- Skip the confirmation popup for simple operations (:help oil.skip_confirm_for_simple_edits)
                skip_confirm_for_simple_edits = true,
                -- Selecting a new/moved/renamed file or directory will prompt you to save changes first
                prompt_save_on_select_new_entry = true,
                -- Keymaps in oil buffer. Can be any value that `vim.keymap.set` accepts OR a table of keymap
                keymaps = {
                    ["g?"] = "actions.show_help",
                    ["<CR>"] = "actions.select",
                    ["<C-s>"] = { "actions.select", opts = { vertical = true }, desc = "Open the entry in a vertical split" },
                    ["<C-h>"] = { "actions.select", opts = { horizontal = true }, desc = "Open the entry in a horizontal split" },
                    ["<C-t>"] = { "actions.select", opts = { tab = true }, desc = "Open the entry in new tab" },
                    ["<C-p>"] = "actions.preview",
                    ["<C-c>"] = "actions.close",
                    ["<C-l>"] = "actions.refresh",
                    ["-"] = "actions.parent",
                    ["_"] = "actions.open_cwd",
                    ["`"] = "actions.cd",
                    ["~"] = { "actions.cd", opts = { scope = "tab" }, desc = ":tcd to the current oil directory" },
                    ["gs"] = "actions.change_sort",
                    ["gx"] = "actions.open_external",
                    ["g."] = "actions.toggle_hidden",
                    ["g\\"] = "actions.toggle_trash", 
                },
                -- Set to false to disable all of the above keymaps
                use_default_keymaps = true,
                view_options = {
                    -- Show files and directories that start with "."
                    show_hidden = false,
                    -- This function defines what is considered a "hidden" file
                    is_hidden_file = function(name, bufnr)
                        return vim.startswith(name, ".")
                    end,
                    -- This function defines what will never be shown, even when `show_hidden` is set
                    is_always_hidden = function(name, bufnr)
                        return false
                    end,
                    -- Sort file names case insensitive
                    case_insensitive = false,
                    sort = {
                        -- sort order can be "asc" or "desc"
                        { "type", "asc" },
                        { "name", "asc" },
                    },
                },
                -- Configuration for the floating window in oil.open_float
                float = {
                    -- Padding around the floating window
                    padding = 2,
                    max_width = 100,
                    max_height = 30,
                    border = "rounded",
                    win_options = {
                        winblend = 0,
                    },
                    -- This is the config that will be passed to nvim_open_win.
                    override = function(conf)
                        return conf
                    end,
                },
                -- Configuration for the actions floating preview window
                preview = {
                    -- Width and height can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
                    max_width = 0.9,
                    -- min_width and min_height can be integers or a float between 0 and 1
                    min_width = { 40, 0.4 },
                    -- optionally define an integer/float for the exact width of the preview window
                    width = nil,
                    -- Height of the floating window can be computed by providing a function that takes the screen height.
                    max_height = 0.9,
                    min_height = { 5, 0.1 },
                    height = nil,
                    border = "rounded",
                    win_options = {
                        winblend = 0,
                    },
                    -- Whether the preview window is automatically updated when the cursor is moved
                    update_on_cursor_moved = true,
                },
                -- Configuration for the floating progress window
                progress = {
                    max_width = 0.9,
                    min_width = { 40, 0.4 },
                    width = nil,
                    max_height = { 10, 0.9 },
                    min_height = { 5, 0.1 },
                    height = nil,
                    border = "rounded",
                    minimized_border = "none",
                    win_options = {
                        winblend = 0,
                    },
                },
                -- Configuration for the floating SSH window
                ssh = {
                    border = "rounded",
                },
            })
        end,
    },

    -- HLCHUNK.NVIM - Beautiful animated scope highlighting (SIMPLIFIED)
    {
        "shellRaining/hlchunk.nvim",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            require("hlchunk").setup({
                chunk = {
                    enable = true,
                    priority = 15,
                    style = {
                        { fg = "#00d7ff" },  -- Bright cyan for current scope
                        { fg = "#ff6b6b" },  -- Red for errors
                    },
                    use_treesitter = true,
                    chars = {
                        horizontal_line = "─",    -- Simple horizontal line
                        vertical_line = "│",     -- Simple vertical line
                        left_top = "┌",          -- Simple top-left corner
                        left_bottom = "└",       -- Simple bottom-left corner
                        right_arrow = "─",       -- Simple arrow
                    },
                    textobject = "",
                    max_file_size = 1024 * 1024,
                    error_sign = false,      -- Disable error signs to prevent issues
                    duration = 200,          -- Shorter duration
                    delay = 50,              -- Less delay
                    support_filetypes = {
                        "lua", "python", "javascript", "typescript", "go", "rust", "c", "cpp", "java"
                    },
                    notify = false,          -- No notifications
                },
                indent = {
                    enable = false,          -- Disable to prevent conflicts
                },
                line_num = {
                    enable = false,          -- Disable to prevent errors
                },
                blank = {
                    enable = false,
                },
            })
        end
    },

    -- NVIM-TREESITTER-CONTEXT - Show current function/class context at top
    {
        "nvim-treesitter/nvim-treesitter-context",
        dependencies = "nvim-treesitter/nvim-treesitter",
        config = function()
            require("treesitter-context").setup({
                enable = true,
                max_lines = 3,            -- Maximum number of lines to show
                min_window_height = 20,   -- Minimum editor window height
                line_numbers = true,
                multiline_threshold = 1,  -- Maximum number of lines to use for a single context line
                trim_scope = 'outer',     -- Which context lines to discard
                mode = 'cursor',          -- Line used to calculate context
                separator = nil,          -- Separator between context and content
                zindex = 20,              -- Z-index of the context window
                on_attach = nil,          -- Callback when attaching to a buffer
            })
            
            -- Set custom highlights for the context
            vim.cmd([[
                hi TreesitterContext guibg=#313244 guifg=#cdd6f4
                hi TreesitterContextBottom gui=underline guisp=#89b4fa
                hi TreesitterContextLineNumber guifg=#89b4fa guibg=#313244
            ]])
        end,
    },
    -- {
    --     "echasnovski/mini.files",
    --     version = false,
    --     keys = {
    --         { "<leader>ef", function() require("mini.files").open(vim.api.nvim_buf_get_name(0), true) end, desc = "Open mini.files (Directory of Current File)" },
    --         { "<leader>eF", function() require("mini.files").open(vim.uv.cwd(), true) end, desc = "Open mini.files (cwd)" },
    --     },
    --     config = function()
    --         require("mini.files").setup({
    --             content = {
    --                 filter = nil,
    --                 prefix = nil,
    --                 sort = nil,
    --             },
    --             mappings = {
    --                 close       = 'q',
    --                 go_in       = 'l',
    --                 go_in_plus  = 'L',
    --                 go_out      = 'h',
    --                 go_out_plus = 'H',
    --                 reset       = '<BS>',
    --                 reveal_cwd  = '@',
    --                 show_help   = 'g?',
    --                 synchronize = '=',
    --                 trim_left   = '<',
    --                 trim_right  = '>',
    --             },
    --             options = {
    --                 permanent_delete = true,
    --                 use_as_default_explorer = false, -- Let oil handle this
    --             },
    --             windows = {
    --                 max_number = math.huge,
    --                 preview = false,
    --                 width_focus = 50,
    --                 width_nofocus = 15,
    --                 width_preview = 25,
    --             },
    --         })
    --         
    --         -- Helper function to toggle dotfiles
    --         local show_dotfiles = true
    --         local filter_show = function(fs_entry) return true end
    --         local filter_hide = function(fs_entry) return not vim.startswith(fs_entry.name, ".") end
    --         local toggle_dotfiles = function()
    --             show_dotfiles = not show_dotfiles
    --             local new_filter = show_dotfiles and filter_show or filter_hide
    --             require("mini.files").refresh({ content = { filter = new_filter } })
    --         end
    --         
    --         vim.api.nvim_create_autocmd('User', {
    --             pattern = 'MiniFilesBufferCreate',
    --             callback = function(args)
    --                 local buf_id = args.data.buf_id
    --                 vim.keymap.set('n', 'g.', toggle_dotfiles, { buffer = buf_id, desc = 'Toggle hidden files' })
    --             end,
    --         })
    --     end,
    -- },

    -- OUTLINE.NVIM - Modern symbols outline with ANIMATIONS
    {
        "hedyhli/outline.nvim",
        lazy = true,
        cmd = { "Outline", "OutlineOpen" },
        keys = {
            { "<leader>o", "<cmd>Outline<CR>", desc = "Toggle outline" },
            { "<leader>so", "<cmd>Outline<CR>", desc = "Symbols outline" },
        },
        opts = {
            outline_window = {
                position = 'right',
                width = 30,
                relative_width = true,
                auto_close = false,
                auto_jump = false,
                jump_highlight_duration = 500, -- Longer highlight duration
                center_on_jump = true,
                show_numbers = false,
                show_relative_numbers = false,
                wrap = false,
                focus_on_open = true,
                winhl = 'Normal:OutlineNormal,FloatBorder:OutlineBorder',
            },
            outline_items = {
                show_symbol_details = true,
                show_symbol_lineno = false,
                highlight_hovered_item = true,
                auto_set_cursor = true,
                auto_update_events = {
                    follow = { 'CursorMoved' },
                    items = { 'InsertLeave', 'WinEnter', 'BufEnter', 'BufWinEnter', 'TabEnter', 'BufWritePost' },
                },
            },
            guides = {
                enabled = true,
                markers = {
                    bottom = '└',
                    middle = '├',
                    vertical = '│',
                },
            },
            symbol_folding = {
                autofold_depth = 1,
                auto_unfold = {
                    hovered = true,
                    only = true,
                },
                markers = { '▶', '▼' }, -- Pretty fold markers
            },
            preview_window = {
                auto_preview = true, -- Enable auto preview for more interactivity
                open_hover_on_preview = true,
                width = 60,
                min_width = 50,
                relative_width = true,
                border = 'rounded',
                winhl = 'NormalFloat:OutlinePreview',
                winblend = 10, -- Slight transparency
                live = true, -- Live preview updates
            },
            keymaps = {
                show_help = '?',
                close = { '<Esc>', 'q' },
                goto_location = '<Cr>',
                peek_location = 'o',
                goto_and_close = '<S-Cr>',
                restore_location = '<C-g>',
                hover_symbol = '<C-space>',
                toggle_preview = 'K',
                rename_symbol = 'r',
                code_actions = 'a',
                fold = 'h',
                unfold = 'l',
                fold_toggle = '<Tab>',
                fold_toggle_all = '<S-Tab>',
                fold_all = 'W',
                unfold_all = 'E',
                fold_reset = 'R',
                down_and_goto = '<C-j>',
                up_and_goto = '<C-k>',
            },
            providers = {
                priority = { 'lsp', 'coc', 'markdown', 'norg' },
                lsp = {
                    blacklist_clients = {},
                },
            },
            symbols = {
                icons = {
                    File = { icon = '󰈔', hl = '@constant' },
                    Module = { icon = '󰆧', hl = '@module' },
                    Namespace = { icon = '󰅪', hl = '@namespace' },
                    Package = { icon = '󰏖', hl = '@module' },
                    Class = { icon = '󰠱', hl = '@type' },
                    Method = { icon = '󰊕', hl = '@method' },
                    Property = { icon = '󰜢', hl = '@property' },
                    Field = { icon = '󰇽', hl = '@field' },
                    Constructor = { icon = '', hl = '@constructor' },
                    Enum = { icon = '󰒻', hl = '@type' },
                    Interface = { icon = '󰜰', hl = '@type' },
                    Function = { icon = '󰊕', hl = '@function' },
                    Variable = { icon = '󰀫', hl = '@variable' },
                    Constant = { icon = '󰏿', hl = '@constant' },
                    String = { icon = '󰉾', hl = '@string' },
                    Number = { icon = '󰎠', hl = '@number' },
                    Boolean = { icon = '◩', hl = '@boolean' },
                    Array = { icon = '󰅪', hl = '@punctuation.bracket' },
                    Object = { icon = '󰅩', hl = '@type' },
                    Key = { icon = '󰌋', hl = '@field' },
                    Null = { icon = 'ﳠ', hl = '@type' },
                    EnumMember = { icon = '󰕘', hl = '@constant' },
                    Struct = { icon = '󰙅', hl = '@structure' },
                    Event = { icon = '󰉁', hl = '@type' },
                    Operator = { icon = '󰆕', hl = '@operator' },
                    TypeParameter = { icon = '󰊄', hl = '@type' },
                    Component = { icon = '󰅴', hl = '@function' },
                    Fragment = { icon = '󰅴', hl = '@constant' },
                    TypeAlias = { icon = '󰉺', hl = '@type' },
                    Parameter = { icon = '󰏪', hl = '@parameter' },
                    StaticMethod = { icon = '󰠄', hl = '@function' },
                    Macro = { icon = '󰘦', hl = '@macro' },
                },
                filter = nil,
            },
        },
        config = function(_, opts)
            require("outline").setup(opts)
            
            -- Set up custom highlight groups for pretty colors
            vim.api.nvim_set_hl(0, 'OutlineNormal', { bg = '#1e1e2e', fg = '#cdd6f4' })
            vim.api.nvim_set_hl(0, 'OutlineBorder', { fg = '#89b4fa' })
            vim.api.nvim_set_hl(0, 'OutlinePreview', { bg = '#181825', fg = '#cdd6f4' })
            
            -- Add animation on outline open/close
            local group = vim.api.nvim_create_augroup("OutlineAnimations", { clear = true })
            vim.api.nvim_create_autocmd("User", {
                group = group,
                pattern = "OutlineOpen",
                callback = function()
                    -- Flash notification when outline opens
                    vim.defer_fn(function()
                        vim.notify("📋 Outline opened", vim.log.levels.INFO, { 
                            title = "Symbols", 
                            timeout = 1000,
                            animate = true 
                        })
                    end, 100)
                end,
            })
        end,
    },

    -- AERIAL.NVIM - Alternative symbols outline (uncomment if you prefer aerial)
    -- {
    --     "stevearc/aerial.nvim",
    --     dependencies = {
    --         "nvim-treesitter/nvim-treesitter",
    --         "nvim-tree/nvim-web-devicons"
    --     },
    --     keys = {
    --         { "<leader>o", "<cmd>AerialToggle!<CR>", desc = "Aerial" },
    --         { "<leader>so", "<cmd>AerialToggle<CR>", desc = "Symbols outline" },
    --         { "<leader>sn", "<cmd>AerialNavToggle<CR>", desc = "Aerial Navigation" },
    --     },
    --     opts = {
    --         -- Priority list of preferred backends for aerial.
    --         backends = { "treesitter", "lsp", "markdown", "man" },
    --         layout = {
    --             max_width = { 40, 0.2 },
    --             width = nil,
    --             min_width = 10,
    --             win_opts = {},
    --             default_direction = "prefer_right",
    --             placement = "window",
    --         },
    --         show_guides = true,
    --         filter_kind = {
    --             "Class",
    --             "Constructor",
    --             "Enum",
    --             "Function",
    --             "Interface",
    --             "Module",
    --             "Method",
    --             "Struct",
    --         },
    --         guides = {
    --             mid_item = "├─",
    --             last_item = "└─",
    --             nested_top = "│ ",
    --             whitespace = "  ",
    --         },
    --         -- Disable on_attach by default to prevent LSP conflicts
    --         on_attach = function(bufnr) end,
    --         -- Automatically open aerial when entering supported files
    --         open_automatic = false,
    --         -- Automatically close aerial when jumping to a symbol
    --         close_automatic_events = {},
    --         keymaps = {
    --             ["?"] = "actions.show_help",
    --             ["g?"] = "actions.show_help",
    --             ["<CR>"] = "actions.jump",
    --             ["<2-LeftMouse>"] = "actions.jump",
    --             ["<C-v>"] = "actions.jump_vsplit",
    --             ["<C-s>"] = "actions.jump_split",
    --             ["p"] = "actions.scroll",
    --             ["<C-j>"] = "actions.down_and_scroll",
    --             ["<C-k>"] = "actions.up_and_scroll",
    --             ["{"] = "actions.prev",
    --             ["}"] = "actions.next",
    --             ["[["] = "actions.prev_up",
    --             ["]]"] = "actions.next_up",
    --             ["q"] = "actions.close",
    --             ["o"] = "actions.tree_toggle",
    --             ["za"] = "actions.tree_toggle",
    --             ["O"] = "actions.tree_toggle_recursive",
    --             ["zA"] = "actions.tree_toggle_recursive",
    --             ["l"] = "actions.tree_open",
    --             ["zo"] = "actions.tree_open",
    --             ["L"] = "actions.tree_open_recursive",
    --             ["zO"] = "actions.tree_open_recursive",
    --             ["h"] = "actions.tree_close",
    --             ["zc"] = "actions.tree_close",
    --             ["H"] = "actions.tree_close_recursive",
    --             ["zC"] = "actions.tree_close_recursive",
    --             ["zr"] = "actions.tree_increase_fold_level",
    --             ["zR"] = "actions.tree_open_all",
    --             ["zm"] = "actions.tree_decrease_fold_level",
    --             ["zM"] = "actions.tree_close_all",
    --             ["zx"] = "actions.tree_sync_folds",
    --             ["zX"] = "actions.tree_sync_folds",
    --         },
    --         lazy_load = true,
    --         disable_max_lines = 10000,
    --         disable_max_size = 2000000, -- Default 2MB
    --         nerd_font = "auto",
    --     },
    -- },

    -- Catppuccin theme - Modern and beautiful
    {
        "catppuccin/nvim",
        name = "catppuccin",
        lazy = false,
        priority = 998,
        config = function()
            require("catppuccin").setup({
                flavour = "mocha", -- latte, frappe, macchiato, mocha
                background = {
                    light = "latte",
                    dark = "mocha",
                },
                transparent_background = false,
                show_end_of_buffer = false,
                term_colors = true,
                dim_inactive = {
                    enabled = false,
                    shade = "dark",
                    percentage = 0.15,
                },
                styles = {
                    comments = { "italic" },
                    conditionals = { "italic" },
                    loops = {},
                    functions = {},
                    keywords = {},
                    strings = {},
                    variables = {},
                    numbers = {},
                    booleans = {},
                    properties = {},
                    types = {},
                    operators = {},
                },
                integrations = {
                    cmp = true,
                    gitsigns = true,
                    telescope = {
                        enabled = true,
                        style = "nvchad",
                    },
                    treesitter = true,
                    which_key = true,
                    native_lsp = {
                        enabled = true,
                        virtual_text = {
                            errors = { "italic" },
                            hints = { "italic" },
                            warnings = { "italic" },
                            information = { "italic" },
                        },
                        underlines = {
                            errors = { "underline" },
                            hints = { "underline" },
                            warnings = { "underline" },
                            information = { "underline" },
                        },
                    },
                    barbecue = {
                        dim_dirname = true,
                        bold_basename = true,
                        dim_context = false,
                        alt_background = false,
                    },
                    aerial = true,
                    snacks = true,
                },
            })
            vim.cmd.colorscheme("catppuccin")
        end,
    },

    -- Alternative beautiful themes
    { "rose-pine/neovim",            name = "rose-pine", lazy = true },
    { "folke/tokyonight.nvim",       lazy = true },
    { "EdenEast/nightfox.nvim",      lazy = true },
    { "rebelot/kanagawa.nvim",       lazy = true },
    { "sainnhe/everforest",          lazy = true },
    { "sainnhe/gruvbox-material",    lazy = true },
    { "projekt0n/github-nvim-theme", lazy = true },
    { "olimorris/onedarkpro.nvim",   lazy = true },

    -- Treesitter for better syntax highlighting 
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        event = { "BufReadPost", "BufNewFile" },
        dependencies = {
            "nvim-treesitter/nvim-treesitter-textobjects",
        },
        config = function()
            require("nvim-treesitter.configs").setup({
                ensure_installed = {
                    "bash", "c", "css", "go", "gomod", "html", "javascript",
                    "json", "lua", "markdown", "markdown_inline", "python", "regex",
                    "tsx", "typescript", "vim", "yaml",
                },
                auto_install = true,
                highlight = {
                    enable = true,
                    additional_vim_regex_highlighting = false,
                },
                indent = { enable = true },
                incremental_selection = {
                    enable = true,
                    keymaps = {
                        init_selection = "<C-space>",
                        node_incremental = "<C-space>",
                        scope_incremental = "<C-s>",
                        node_decremental = "<C-backspace>",
                    },
                },
                textobjects = {
                    select = {
                        enable = true,
                        lookahead = true,
                        keymaps = {
                            ["af"] = "@function.outer",
                            ["if"] = "@function.inner",
                            ["ac"] = "@class.outer",
                            ["ic"] = "@class.inner",
                            ["ab"] = "@block.outer",
                            ["ib"] = "@block.inner",
                        },
                    },
                    move = {
                        enable = true,
                        set_jumps = true,
                        goto_next_start = {
                            ["]m"] = "@function.outer",
                            ["]]"] = "@class.outer",
                        },
                        goto_next_end = {
                            ["]M"] = "@function.outer",
                            ["]["] = "@class.outer",
                        },
                        goto_previous_start = {
                            ["[m"] = "@function.outer",
                            ["[["] = "@class.outer",
                        },
                        goto_previous_end = {
                            ["[M"] = "@function.outer",
                            ["[]"] = "@class.outer",
                        },
                    },
                },
            })
        end,
    },

    -- Telescope for fuzzy finding
    {
        "nvim-telescope/telescope.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            {
                "nvim-telescope/telescope-fzf-native.nvim",
                build = "make",
            },
            "nvim-tree/nvim-web-devicons",
        },
        cmd = "Telescope",
        keys = {
            { "<leader>ff", "<cmd>Telescope find_files<cr>",           desc = "Find Files" },
            { "<leader>fg", "<cmd>Telescope live_grep<cr>",            desc = "Find in Files" },
            { "<leader>fb", "<cmd>Telescope buffers<cr>",              desc = "Find Buffers" },
            { "<leader>fh", "<cmd>Telescope help_tags<cr>",            desc = "Find Help" },
            { "<leader>fr", "<cmd>Telescope oldfiles<cr>",             desc = "Recent Files" },
            { "<leader>fc", "<cmd>Telescope colorscheme<cr>",          desc = "Colorschemes" },
            { "<leader>fs", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Document Symbols" },
            { "<leader>fS", "<cmd>Telescope aerial<cr>",               desc = "Symbols (Aerial)" },
            { "<leader>fd", "<cmd>Telescope diagnostics<cr>",          desc = "Diagnostics" },
        },
        config = function()
            local telescope = require("telescope")
            local actions = require("telescope.actions")

            telescope.setup({
                defaults = {
                    file_ignore_patterns = { "node_modules", ".git" },
                    path_display = { "truncate" },
                    sorting_strategy = "ascending",
                    layout_config = {
                        horizontal = {
                            prompt_position = "top",
                            preview_width = 0.55,
                        },
                        width = 0.87,
                        height = 0.80,
                    },
                    mappings = {
                        i = {
                            ["<C-j>"] = actions.move_selection_next,
                            ["<C-k>"] = actions.move_selection_previous,
                            ["<C-c>"] = actions.close,
                            ["<Esc>"] = actions.close,
                        },
                    },
                },
                pickers = {
                    find_files = {
                        hidden = true,
                    },
                    buffers = {
                        sort_lastused = true,
                    },
                },
                extensions = {
                    fzf = {
                        fuzzy = true,
                        override_generic_sorter = true,
                        override_file_sorter = true,
                        case_mode = "smart_case",
                    },
                },
            })

            telescope.load_extension("fzf")
            -- Load aerial extension if arial is enabled
            -- telescope.load_extension("aerial")
        end,
    },

    -- LSP Configuration - FIXED for Python LSP conflicts
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            -- LSP Support
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "WhoIsSethDaniel/mason-tool-installer.nvim",

            -- Useful status updates for LSP
            { "j-hui/fidget.nvim", tag = "legacy", opts = {} },

            -- Additional lua configuration, makes nvim stuff amazing!
            "folke/neodev.nvim",
        },
        config = function()
            -- Setup neovim lua configuration
            require("neodev").setup()

            -- Setup mason so it can manage external tooling
            require("mason").setup({
                ui = {
                    border = "rounded",
                    icons = {
                        package_installed = "✓",
                        package_pending = "➜",
                        package_uninstalled = "✗",
                    },
                },
            })

            -- FIXED: Single Python LSP configuration to prevent conflicts
            local servers = {
                lua_ls = {
                    Lua = {
                        workspace = { checkThirdParty = false },
                        telemetry = { enable = false },
                        diagnostics = { globals = { 'vim' } },
                    },
                },
                -- Use only basedpyright for Python (faster than pyright)
                basedpyright = {
                    basedpyright = {
                        disableOrganizeImports = true, -- Let ruff handle this
                        analysis = {
                            typeCheckingMode = "basic",
                            diagnosticMode = "openFilesOnly",
                            autoSearchPaths = true,
                            useLibraryCodeForTypes = true,
                        },
                    },
                },
                ruff = {
                    settings = {
                        args = {
                            "--config=pyproject.toml", -- Use project ruff config if available
                        },
                    },
                },
                tsserver = {},
                gopls = {
                    gopls = {
                        analyses = {
                            unusedparams = true,
                        },
                        staticcheck = true,
                        gofumpt = true,
                    },
                },
            }

            -- Install formatters and linters - SELECTIVE to avoid conflicts
            require("mason-tool-installer").setup({
                ensure_installed = {
                    "stylua",        -- Lua formatter
                    "basedpyright",  -- Python LSP (instead of pyright)
                    "ruff",          -- Python linter and formatter (will handle both)
                    "prettier",      -- JS/TS formatter
                    "eslint_d",      -- JS/TS linter
                    "gofumpt",       -- Go formatter
                    "golangci-lint", -- Go linter
                },
                auto_update = false,
                run_on_start = false, -- Prevent auto-installation conflicts
            })

            -- Ensure the servers listed above are installed
            local mason_lspconfig = require "mason-lspconfig"

            mason_lspconfig.setup {
                ensure_installed = vim.tbl_keys(servers),
                automatic_installation = false, -- Prevent conflicts
            }

            -- nvim-cmp supports additional completion capabilities
            local capabilities = vim.lsp.protocol.make_client_capabilities()
            capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

            -- Prevent multiple LSP attachment to same buffer
            local active_clients = {}

            -- Set up on_attach function with conflict prevention
            local on_attach = function(client, bufnr)
                local ft = vim.bo[bufnr].filetype
                
                -- For Python files, ensure only one LSP is active
                if ft == "python" then
                    if active_clients[bufnr] then
                        -- If another client is already attached, detach this one
                        vim.lsp.buf_detach_client(bufnr, client.id)
                        return
                    end
                    active_clients[bufnr] = client.id
                    
                    -- Clean up when buffer is deleted
                    autocmd("BufDelete", {
                        buffer = bufnr,
                        callback = function()
                            active_clients[bufnr] = nil
                        end,
                    })
                end

                lsp_mappings(client, bufnr)

                -- Configure Python LSP responsibilities
                if ft == "python" then
                    if client.name == "ruff" then
                        -- Ruff handles formatting and organizing imports
                        client.server_capabilities.documentFormattingProvider = true
                        client.server_capabilities.documentRangeFormattingProvider = true
                    elseif client.name == "basedpyright" then
                        -- basedpyright handles hover, completion, diagnostics
                        client.server_capabilities.documentFormattingProvider = false
                        client.server_capabilities.documentRangeFormattingProvider = false
                    end
                end
            end

            -- Configure servers individually to prevent conflicts
            local lspconfig = require("lspconfig")
            
            -- Set up basedpyright for Python
            lspconfig.basedpyright.setup({
                on_attach = on_attach,
                capabilities = capabilities,
                settings = servers.basedpyright,
                single_file_support = true,
            })

            -- Set up ruff for Python formatting/linting
            lspconfig.ruff.setup({
                on_attach = on_attach,
                capabilities = capabilities,
                init_options = {
                    settings = {
                        format = { enabled = true },
                        lint = { enabled = true },
                        organizeImports = true,
                    }
                },
            })

            -- Set up other language servers
            for server_name, settings in pairs(servers) do
                if server_name ~= "basedpyright" and server_name ~= "ruff" then
                    lspconfig[server_name].setup {
                        capabilities = capabilities,
                        on_attach = on_attach,
                        settings = settings,
                    }
                end
            end

            -- Configure UI
            local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
            function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
                opts = opts or {}
                opts.border = opts.border or "rounded"
                return orig_util_open_floating_preview(contents, syntax, opts, ...)
            end
        end,
    },

    -- Autocompletion
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-nvim-lua",
            "rafamadriz/friendly-snippets",
        },
        config = function()
            local cmp = require("cmp")
            local luasnip = require("luasnip")
            require("luasnip.loaders.from_vscode").lazy_load()

            cmp.setup({
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },
                window = {
                    completion = cmp.config.window.bordered(),
                    documentation = cmp.config.window.bordered(),
                },
                mapping = cmp.mapping.preset.insert({
                    ["<C-d>"] = cmp.mapping.scroll_docs(-4),
                    ["<C-f>"] = cmp.mapping.scroll_docs(4),
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<CR>"] = cmp.mapping.confirm {
                        behavior = cmp.ConfirmBehavior.Replace,
                        select = true,
                    },
                    ["<Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_next_item()
                        elseif luasnip.expand_or_jumpable() then
                            luasnip.expand_or_jump()
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                    ["<S-Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_prev_item()
                        elseif luasnip.jumpable(-1) then
                            luasnip.jump(-1)
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp" },
                    { name = "nvim_lua" },
                    { name = "luasnip" },
                    { name = "buffer" },
                    { name = "path" },
                }),
                formatting = {
                    format = function(entry, vim_item)
                        -- Simple kind icons
                        local kind_icons = {
                            Text = "",
                            Method = "",
                            Function = "",
                            Constructor = "",
                            Field = "",
                            Variable = "",
                            Class = "",
                            Interface = "",
                            Module = "",
                            Property = "",
                            Unit = "",
                            Value = "",
                            Enum = "",
                            Keyword = "",
                            Snippet = "",
                            Color = "",
                            File = "",
                            Reference = "",
                            Folder = "",
                            EnumMember = "",
                            Constant = "",
                            Struct = "",
                            Event = "",
                            Operator = "",
                            TypeParameter = "",
                        }
                        vim_item.kind = string.format('%s %s', kind_icons[vim_item.kind], vim_item.kind)
                        return vim_item
                    end
                },
            })
        end,
    },

    -- Status line
    {
        "nvim-lualine/lualine.nvim",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },
        config = function()
            require("lualine").setup({
                options = {
                    icons_enabled = true,
                    theme = "catppuccin",
                    component_separators = { left = "", right = "" },
                    section_separators = { left = "", right = "" },
                    globalstatus = true,
                },
                sections = {
                    lualine_a = { "mode" },
                    lualine_b = {
                        "branch",
                        {
                            "diff",
                            colored = true,
                            symbols = { added = " ", modified = " ", removed = " " },
                        },
                        {
                            "diagnostics",
                            sources = { "nvim_diagnostic" },
                            symbols = { error = " ", warn = " ", info = " ", hint = " " },
                        }
                    },
                    lualine_c = { { "filename", path = 1 } },
                    lualine_x = { "encoding", "fileformat", "filetype" },
                    lualine_y = { "progress" },
                    lualine_z = { "location" },
                },
            })
        end,
    },

    -- Better buffer line
    {
        "akinsho/bufferline.nvim",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },
        version = "*",
        config = function()
            require("bufferline").setup({
                options = {
                    mode = "buffers",
                    numbers = "ordinal",
                    diagnostics = "nvim_lsp",
                    separator_style = "thin",
                    show_buffer_close_icons = true,
                    show_close_icon = true,
                    color_icons = true,
                },
            })
        end,
    },

    -- Git signs in the gutter
    {
        "lewis6991/gitsigns.nvim",
        config = function()
            require("gitsigns").setup({
                signs = {
                    add = { text = "▎" },
                    change = { text = "▎" },
                    delete = { text = "_" },
                    topdelete = { text = "‾" },
                    changedelete = { text = "~" },
                },
                current_line_blame = false,
                on_attach = function(bufnr)
                    local gs = package.loaded.gitsigns

                    -- Navigation
                    vim.keymap.set("n", "]c", function()
                        if vim.wo.diff then return "]c" end
                        vim.schedule(function() gs.next_hunk() end)
                        return "<Ignore>"
                    end, { expr = true, buffer = bufnr })

                    vim.keymap.set("n", "[c", function()
                        if vim.wo.diff then return "[c" end
                        vim.schedule(function() gs.prev_hunk() end)
                        return "<Ignore>"
                    end, { expr = true, buffer = bufnr })

                    -- Actions
                    vim.keymap.set("n", "<leader>gh", gs.preview_hunk, { buffer = bufnr, desc = "Preview git hunk" })
                    vim.keymap.set("n", "<leader>gb", function() gs.blame_line({ full = true }) end,
                        { buffer = bufnr, desc = "Blame line" })
                end,
            })
        end,
    },

    -- Terminal integration
    {
        "akinsho/toggleterm.nvim",
        version = "*",
        config = function()
            require("toggleterm").setup({
                size = 20,
                open_mapping = [[<c-\>]],
                hide_numbers = true,
                shade_filetypes = {},
                shade_terminals = true,
                shading_factor = 2,
                start_in_insert = true,
                insert_mappings = true,
                persist_size = true,
                direction = "float",
                close_on_exit = true,
                shell = vim.o.shell,
                float_opts = {
                    border = "curved",
                    winblend = 0,
                    highlights = {
                        border = "Normal",
                        background = "Normal",
                    },
                },
            })
        end,
    },

    -- Auto pairs
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        config = function()
            require("nvim-autopairs").setup({
                check_ts = true,
                ts_config = {
                    lua = { "string", "source" },
                    javascript = { "string", "template_string" },
                },
            })
        end,
    },

    -- Commenting
    {
        "numToStr/Comment.nvim",
        config = function()
            require("Comment").setup()
        end,
    },

    -- Enhanced indent and scope highlighting (DISABLED - using snacks.indent instead)
    -- {
    --     "lukas-reineke/indent-blankline.nvim",
    --     main = "ibl",
    --     config = function()
    --         require("ibl").setup({
    --             indent = {
    --                 char = "│",
    --                 tab_char = "│",
    --             },
    --             scope = {
    --                 enabled = false, -- We'll use snacks.scope for scope
    --             },
    --             exclude = {
    --                 filetypes = {
    --                     "help", "alpha", "dashboard", "neo-tree", "Trouble",
    --                     "trouble", "lazy", "mason", "notify", "toggleterm", "lazyterm",
    --                 },
    --             },
    --         })
    --     end,
    -- },

    -- Beautiful UI with Noice
    {
        "folke/noice.nvim",
        dependencies = {
            "MunifTanjim/nui.nvim",
        },
        event = "VeryLazy",
        config = function()
            require("noice").setup({
                lsp = {
                    override = {
                        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                        ["vim.lsp.util.stylize_markdown"] = true,
                        ["cmp.entry.get_documentation"] = true,
                    },
                    signature = {
                        enabled = true,
                        auto_open = {
                            enabled = true,
                            trigger = true,
                            luasnip = true,
                            throttle = 50,
                        },
                    },
                    hover = {
                        enabled = true,
                        silent = false,
                    },
                },
                cmdline = {
                    enabled = true,
                    view = "cmdline_popup",
                    opts = {
                        position = {
                            row = "50%",
                            col = "50%",
                        },
                        size = {
                            width = 60,
                            height = "auto",
                        },
                    },
                    format = {
                        cmdline = { pattern = "^:", icon = "❯", lang = "vim" },
                        search_down = { kind = "search", pattern = "^/", icon = "🔍", lang = "regex" },
                        search_up = { kind = "search", pattern = "^%?", icon = "🔍", lang = "regex" },
                        filter = { pattern = "^:%s*!", icon = "$", lang = "bash" },
                        lua = { pattern = { "^:%s*lua%s+", "^:%s*lua%s*=%s*", "^:%s*=%s*" }, icon = "", lang = "lua" },
                        help = { pattern = "^:%s*he?l?p?%s+", icon = "❓" },
                    },
                },
                messages = {
                    enabled = true,
                    view = "mini",
                    view_error = "mini",
                    view_warn = "mini",
                    view_history = "messages",
                    view_search = "virtualtext",
                },
                popupmenu = {
                    enabled = true,
                    backend = "nui",
                    kind_icons = {},
                },
                views = {
                    cmdline_popup = {
                        position = {
                            row = "50%",
                            col = "50%",
                        },
                        size = {
                            width = 60,
                            height = "auto",
                        },
                        border = {
                            style = "rounded",
                            padding = { 0, 1 },
                        },
                        filter_options = {},
                        win_options = {
                            winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder",
                        },
                    },
                },
                routes = {
                    {
                        filter = {
                            event = "msg_show",
                            kind = "",
                            find = "written",
                        },
                        opts = { skip = true },
                    },
                    {
                        filter = {
                            event = "msg_show",
                            kind = "",
                            find = "LSP.*attached",
                        },
                        opts = { skip = true },
                    },
                },
                presets = {
                    bottom_search = false,
                    command_palette = true,
                    long_message_to_split = true,
                    inc_rename = false,
                    lsp_doc_border = true,
                },
            })
        end,
    },

    -- VS Code like breadcrumbs - BARBECUE
    {
        "utilyre/barbecue.nvim",
        name = "barbecue",
        version = "*",
        dependencies = {
            "SmiteshP/nvim-navic",
            "nvim-tree/nvim-web-devicons",
        },
        config = function()
            require("barbecue").setup({
                attach_navic = true,
                create_autocmd = true,
                include_buftypes = { "" },
                exclude_filetypes = { "netrw", "toggleterm", "alpha" },
                modifiers = {
                    dirname = ":~:.",
                    basename = "",
                },
                show_dirname = true,
                show_basename = true,
                show_modified = false,
                show_navic = true,
                theme = "catppuccin",
            })
        end,
    },

    -- Floating statuslines - INCLINE
    {
        "b0o/incline.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("incline").setup({
                debounce_threshold = {
                    falling = 50,
                    rising = 10
                },
                hide = {
                    cursorline = false,
                    focused_win = false,
                    only_win = false
                },
                highlight = {
                    groups = {
                        InclineNormal = {
                            guibg = "#a6adc8",
                            guifg = "#1e1e2e"
                        },
                        InclineNormalNC = {
                            guifg = "#a6adc8",
                            guibg = "#313244"
                        },
                    },
                },
                ignore = {
                    buftypes = "special",
                    filetypes = {},
                    floating_wins = true,
                    unlisted_buffers = true,
                    wintypes = "special"
                },
                render = function(props)
                    local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
                    if vim.bo[props.buf].modified then
                        filename = "[+] " .. filename
                    end
                    local icon, color = require("nvim-web-devicons").get_icon_color(filename)
                    return { { icon, guifg = color }, { " " }, { filename } }
                end,
                window = {
                    margin = {
                        horizontal = 1,
                        vertical = 1
                    },
                    options = {
                        signcolumn = "no",
                        wrap = false
                    },
                    padding = 1,
                    padding_char = " ",
                    placement = {
                        horizontal = "right",
                        vertical = "top"
                    },
                    width = "fit",
                    winhighlight = {
                        active = {
                            EndOfBuffer = "None",
                            Normal = "InclineNormal",
                            Search = "None"
                        },
                        inactive = {
                            EndOfBuffer = "None",
                            Normal = "InclineNormalNC",
                            Search = "None"
                        }
                    },
                    zindex = 50
                }
            })
        end,
    },

    -- Enhanced folding - NVIM-UFO
    {
        "kevinhwang91/nvim-ufo",
        dependencies = "kevinhwang91/promise-async",
        config = function()
            vim.o.foldcolumn = '1'
            vim.o.foldlevel = 99
            vim.o.foldlevelstart = 99
            vim.o.foldenable = true

            vim.keymap.set('n', 'zR', require('ufo').openAllFolds)
            vim.keymap.set('n', 'zM', require('ufo').closeAllFolds)

            require('ufo').setup({
                provider_selector = function(bufnr, filetype, buftype)
                    return { 'treesitter', 'indent' }
                end
            })
        end,
    },

    -- File switching - HARPOON
    {
        "ThePrimeagen/harpoon",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            require("harpoon").setup({
                global_settings = {
                    save_on_toggle = false,
                    save_on_change = true,
                    enter_on_sendcmd = false,
                    tmux_autoclose_windows = false,
                    excluded_filetypes = { "harpoon" },
                    mark_branch = false,
                },
                menu = {
                    width = vim.api.nvim_win_get_width(0) - 4,
                }
            })

            -- Keymaps
            vim.keymap.set("n", "<leader>a", function()
                require("harpoon.mark").add_file()
                vim.notify("Added to Harpoon!", "info", { title = "Harpoon" })
            end, { desc = "Add file to Harpoon" })

            vim.keymap.set("n", "<C-e>", function()
                require("harpoon.ui").toggle_quick_menu()
            end, { desc = "Toggle Harpoon menu" })

            vim.keymap.set("n", "<C-1>", function()
                require("harpoon.ui").nav_file(1)
            end, { desc = "Navigate to file 1" })

            vim.keymap.set("n", "<C-2>", function()
                require("harpoon.ui").nav_file(2)
            end, { desc = "Navigate to file 2" })

            vim.keymap.set("n", "<C-3>", function()
                require("harpoon.ui").nav_file(3)
            end, { desc = "Navigate to file 3" })

            vim.keymap.set("n", "<C-4>", function()
                require("harpoon.ui").nav_file(4)
            end, { desc = "Navigate to file 4" })
        end,
    },

    -- Which-key for key binding hints
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        config = function()
            require("which-key").setup({
                plugins = {
                    marks = true,
                    registers = true,
                    spelling = {
                        enabled = true,
                        suggestions = 20,
                    },
                    presets = {
                        operators = true,
                        motions = true,
                        text_objects = true,
                        windows = true,
                        nav = true,
                        z = true,
                        g = true,
                    },
                },
                window = {
                    border = "rounded",
                    padding = { 2, 2, 2, 2 },
                },
                layout = {
                    height = { min = 4, max = 25 },
                    width = { min = 20, max = 50 },
                    spacing = 3,
                },
                icons = {
                    breadcrumb = "»",
                    separator = "➜",
                    group = "+",
                },
            })

            -- Fix: Use the correct which-key.add() method (v3 syntax)
            require("which-key").add({
                { "<leader>f", group = "Find" },
                { "<leader>g", group = "Git" },
                { "<leader>l", group = "LSP" },
                { "<leader>u", group = "Toggle UI" },
                { "<leader>e", desc = "Open Explorer" },
                { "<leader>s", group = "Symbols" },
            })
        end,
    },

    -- Word highlighting
    {
        "RRethy/vim-illuminate",
        config = function()
            require('illuminate').configure({
                providers = {
                    'lsp',
                    'treesitter',
                    'regex',
                },
                delay = 100,
                under_cursor = true,
                min_count_to_highlight = 1,
            })
        end
    },

    -- TODO comments
    {
        "folke/todo-comments.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            require("todo-comments").setup({
                signs = true,
                keywords = {
                    FIX = { icon = " ", color = "error", alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
                    TODO = { icon = " ", color = "info" },
                    HACK = { icon = " ", color = "warning" },
                    WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
                    PERF = { icon = " ", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
                    NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
                },
                highlight = {
                    before = "",
                    keyword = "wide",
                    after = "fg",
                    pattern = [[.*<(KEYWORDS)\s*:]],
                    comments_only = true,
                },
            })
        end
    },
}

-- Setup lazy.nvim
require("lazy").setup(plugins, {
    change_detection = {
        notify = false,
    },
    performance = {
        rtp = {
            disabled_plugins = {
                "gzip",
                "tarPlugin",
                "tohtml",
                "tutor",
                "zipPlugin",
            },
        },
    },
    ui = {
        border = "rounded",
    },
})
