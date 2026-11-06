-- Linked to ~/.config/nvim by install/nvim.sh, which also fetches the
-- plugins (fzf-lua, nvim-tree) into Neovim's package directory; a
-- missing plugin or language server is skipped along with its keys.
--
-- Keys (leader is Space):
--   <leader>f   find files            <leader>g   grep the project
--   <leader>/   search this file      <leader>b   open buffers
--   <leader>r   resume last search    <leader>e   file tree
--   <leader>h/j/k/l  move to the window left/down/up/right
--   <Esc>       clear search highlight
--   <leader>?   key reminders in the statusline: files, code, off
--
-- In Go, C and C++ files (gopls, clangd):
--   gd   go to definition             K    docs for the symbol
--   grr  references                   grn  rename
--   gra  code actions (fixes)         ]d [d  next/previous problem
--   C-w d  problem details            C-y  accept completion

vim.g.mapleader = " "
vim.g.maplocalleader = " "

local o = vim.opt
o.number = true
o.relativenumber = true
o.signcolumn = "yes"
o.cursorline = true
o.scrolloff = 8
o.wrap = false
o.mouse = "a"
o.undofile = true
o.splitright = true
o.splitbelow = true
o.ignorecase = true
o.smartcase = true
o.expandtab = true
o.shiftwidth = 4
o.tabstop = 4
o.laststatus = 3                      -- one statusline for all windows
o.winborder = "rounded"               -- floating windows
o.fillchars = { eob = " " }           -- no ~ past the end of the file
o.list = true
o.listchars = { tab = "  ", trail = "·", nbsp = "␣" }  -- tabs blank: Go uses them

-- System clipboard, when a provider (wl-copy, xclip, ...) exists.
if vim.fn.has("clipboard") == 1 then
    o.clipboard = "unnamedplus"
end

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>")
vim.keymap.set("n", "<leader>h", "<C-w>h", { desc = "Window left" })
vim.keymap.set("n", "<leader>j", "<C-w>j", { desc = "Window below" })
vim.keymap.set("n", "<leader>k", "<C-w>k", { desc = "Window above" })
vim.keymap.set("n", "<leader>l", "<C-w>l", { desc = "Window right" })

-- Statusline: file name on the left, reminders of the keys that work
-- in the current window on the right (␣ is Space). In a file, ␣? steps
-- through the pages of reminders, then hides them.
local pages = {
    "␣f files  ␣g grep  ␣/ this file  ␣b buffers  ␣e tree  ␣r resume"
        .. "  C-^ last file  ␣hjkl splits  ␣? code keys",
    "gd definition  K docs  grr references  grn rename  gra fix"
        .. "  ]d [d problems  C-w d details  C-y accept  ␣? hide",
}
local hints = {
    NvimTree = "enter open  C-v side  C-x below  a new  r rename  d delete"
        .. "  H dotfiles  g? all keys",
    fzf = "enter open  C-v side  C-s below  C-t tab  esc close",
}
local labels = { NvimTree = "files", fzf = "search" }
vim.g.key_hints = 1

function _G.statusline()
    local ft = vim.bo[vim.api.nvim_win_get_buf(vim.g.statusline_winid)].filetype
    local left = labels[ft] and " " .. labels[ft] or " %<%f %m%r"
    if vim.g.key_hints == 0 then
        return left .. "%=%l:%c "
    end
    local h = hints[ft] or pages[vim.g.key_hints]
    return left .. "%=%#Comment#" .. h .. "%* "
end
o.statusline = "%!v:lua.statusline()"

vim.keymap.set("n", "<leader>?", function()
    vim.g.key_hints = (vim.g.key_hints + 1) % (#pages + 1)
    vim.cmd.redrawstatus()
end, { desc = "Next page of key reminders" })

-- Briefly highlight yanked text.
vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function() vim.hl.on_yank() end,
})

-- fzf-lua: fuzzy pickers on top of fzf; lists files with fd and greps
-- with rg when they are installed.
local ok, fzf = pcall(require, "fzf-lua")
if ok then
    fzf.setup({
        defaults = { file_icons = false, git_icons = false },
        winopts = { height = 0.85, width = 0.85 },
    })
    vim.keymap.set("n", "<leader>f", fzf.files, { desc = "Find files" })
    vim.keymap.set("n", "<leader>g", fzf.live_grep, { desc = "Grep the project" })
    vim.keymap.set("n", "<leader>/", fzf.blines, { desc = "Search this file" })
    vim.keymap.set("n", "<leader>b", fzf.buffers, { desc = "Open buffers" })
    vim.keymap.set("n", "<leader>r", fzf.resume, { desc = "Resume last search" })
end

-- nvim-tree: file tree on the left, opened on the current file. Plain
-- arrows instead of icons, so no Nerd Font is needed; git status shows
-- as the colour of the name.
local ok_tree, tree = pcall(require, "nvim-tree")
if ok_tree then
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
    tree.setup({
        view = { width = 32 },
        renderer = {
            root_folder_label = ":t",
            highlight_git = "name",
            indent_markers = { enable = true },
            icons = {
                show = {
                    file = false,
                    folder = false,
                    git = false,
                    modified = false,
                    diagnostics = false,
                    bookmarks = false,
                },
                glyphs = { folder = { arrow_closed = "▸", arrow_open = "▾" } },
            },
        },
        filters = { custom = { "^.git$" } },
    })
    vim.keymap.set("n", "<leader>e", function()
        local api = require("nvim-tree.api")
        if api.tree.is_tree_buf() then
            api.tree.close()
        else
            api.tree.find_file({ open = true, focus = true })
        end
    end, { desc = "File tree" })
end

-- Language servers, through Neovim's built-in client: gopls for Go,
-- clangd for C and C++, tinymist for Typst. Each is enabled only when
-- on PATH when nvim starts: with Nix, from the project's devShell
-- (direnv loads it on cd, so start nvim inside the project); without,
-- from install/gopls.sh and install/clangd.sh. clangd needs
-- compile_commands.json for projects with include paths or flags; with
-- CMake, configure with -DCMAKE_EXPORT_COMPILE_COMMANDS=ON.
vim.lsp.config("gopls", {
    cmd = { "gopls" },
    filetypes = { "go", "gomod", "gowork", "gotmpl" },
    root_markers = { "go.work", "go.mod", ".git" },
})
vim.lsp.config("clangd", {
    cmd = { "clangd" },
    filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
    root_markers = { ".clangd", "compile_commands.json", "compile_flags.txt", ".git" },
})
vim.lsp.config("tinymist", {
    cmd = { "tinymist", "lsp" },
    filetypes = { "typst" },
    root_markers = { ".git" },
})
for _, name in ipairs({ "gopls", "clangd", "tinymist" }) do
    if vim.fn.executable(vim.lsp.config[name].cmd[1]) == 1 then
        vim.lsp.enable(name)
    end
end

-- Problems at the end of their line, errors first.
vim.diagnostic.config({ virtual_text = true, severity_sort = true })

-- Completion pops up as you type; C-n/C-p move, C-y accepts, C-e closes.
o.completeopt = { "menuone", "noselect", "popup", "fuzzy" }

vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if client:supports_method("textDocument/completion") then
            vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
        end
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = ev.buf, desc = "Go to definition" })
    end,
})

-- Go files are tidied on save, like goimports: imports added, removed
-- and sorted, then the file formatted.
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*.go",
    callback = function(ev)
        local client = vim.lsp.get_clients({ bufnr = ev.buf, name = "gopls" })[1]
        if not client then
            return
        end
        local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
        params.context = { only = { "source.organizeImports" }, diagnostics = {} }
        local res = client:request_sync("textDocument/codeAction", params, 2000, ev.buf)
        for _, action in ipairs(res and res.result or {}) do
            if action.edit then
                vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
            end
        end
        vim.lsp.buf.format({ bufnr = ev.buf, id = client.id, timeout_ms = 2000 })
    end,
})
