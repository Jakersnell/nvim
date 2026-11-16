-- Code review in the terminal
--  diffview.nvim: file panel + side-by-side diffs for the working tree, a branch, or file history
-- https://github.com/sindrets/diffview.nvim

vim.pack.add { 'https://github.com/sindrets/diffview.nvim' }

-- [[ Local diffs ]]
local close_diffview = { 'n', 'q', '<Cmd>DiffviewClose<CR>', { desc = 'Close diffview' } }
require('diffview').setup {
  enhanced_diff_hl = true,
  -- `q` closes from the side panels only; in the diff buffers it stays macro-record
  keymaps = {
    file_panel = { close_diffview },
    file_history_panel = { close_diffview },
  },
}

-- The ref a PR from this branch would target: origin's default branch, else a common name.
local function base_ref()
  local head = vim.fn.systemlist({ 'git', 'symbolic-ref', '--short', 'refs/remotes/origin/HEAD' })[1]
  if vim.v.shell_error == 0 and head and head ~= '' then return head end
  for _, ref in ipairs { 'origin/main', 'origin/master', 'main', 'master' } do
    vim.fn.system { 'git', 'rev-parse', '--verify', '--quiet', ref }
    if vim.v.shell_error == 0 then return ref end
  end
end

-- Everything this branch changed since it forked from the base branch (what a PR would show).
local function review_branch()
  local base = base_ref()
  if not base then
    vim.notify('No base branch found (tried origin/HEAD, main, master)', vim.log.levels.WARN)
    return
  end
  vim.cmd.DiffviewOpen(base .. '...HEAD')
end

local map = function(lhs, rhs, desc, mode) vim.keymap.set(mode or 'n', lhs, rhs, { desc = desc }) end
map('<leader>gd', '<Cmd>DiffviewOpen<CR>', '[G]it [D]iff uncommitted changes')
map('<leader>gb', review_branch, '[G]it diff [B]ranch against base (PR view)')
map('<leader>gf', '<Cmd>DiffviewFileHistory %<CR>', '[G]it [F]ile history')
map('<leader>gf', ":'<,'>DiffviewFileHistory<CR>", '[G]it history of selected lines', 'x')
map('<leader>gl', '<Cmd>DiffviewFileHistory<CR>', '[G]it [L]og (repo history)')
map('<leader>gq', '<Cmd>DiffviewClose<CR>', '[G]it diff [Q]uit')
