-- Linked to ~/.config/nvim by install/nvim.sh, which also fetches the
-- plugins (fzf-lua, nvim-tree) into Neovim's package directory; a
-- missing plugin is skipped along with its keys.
--
-- Keys (leader is Space):
--   <leader>f   find files            <leader>g   grep the project
--   <leader>/   search this file      <leader>b   open buffers
--   <leader>r   resume last search    <leader>e   file tree
--   <Esc>       clear search highlight
--   <leader>?   show/hide key reminders in the statusline

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
o.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- System clipboard, when a provider (wl-copy, xclip, ...) exists.
if vim.fn.has("clipboard") == 1 then
    o.clipboard = "unnamedplus"
end

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>")

-- Statusline: file name on the left, reminders of the keys that work
-- in the current window on the right (␣ is Space).
local hints = {
    default = "␣f files  ␣g grep  ␣/ this file  ␣b buffers  ␣e tree  ␣r resume"
        .. "  C-^ last file  C-w hjkl splits  ␣? hide",
    NvimTree = "enter open  C-v side  C-x below  a new  r rename  d delete"
        .. "  H dotfiles  g? all keys",
    fzf = "enter open  C-v side  C-s below  C-t tab  esc close",
}
local labels = { NvimTree = "files", fzf = "search" }
vim.g.key_hints = true

function _G.statusline()
    local ft = vim.bo[vim.api.nvim_win_get_buf(vim.g.statusline_winid)].filetype
    local left = labels[ft] and " " .. labels[ft] or " %<%f %m%r"
    if not vim.g.key_hints then
        return left .. "%=%l:%c "
    end
    local h = hints[ft] or hints.default
    return left .. "%=%#Comment#" .. h .. "%* "
end
o.statusline = "%!v:lua.statusline()"

vim.keymap.set("n", "<leader>?", function()
    vim.g.key_hints = not vim.g.key_hints
    vim.cmd.redrawstatus()
end, { desc = "Show/hide key reminders" })

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
    vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeFindFileToggle<cr>", { desc = "File tree" })
end
