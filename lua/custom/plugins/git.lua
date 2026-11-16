-- Code review in the terminal
--  codediff.nvim: VS Code-style diffs (line + character highlighting) with a source-control panel,
--    for the working tree, a branch, or file history. Downloads its diff library on first use.
--  octo.nvim: GitHub PRs inside nvim (threads, line comments, submitting reviews) via the `gh` CLI
-- https://github.com/esmuellert/codediff.nvim
-- https://github.com/pwntester/octo.nvim

vim.pack.add {
  'https://github.com/esmuellert/codediff.nvim',
  'https://github.com/pwntester/octo.nvim',
}

-- [[ Local diffs ]]
-- Each review opens in its own tab. Inside it: `q` closes, `t` toggles side-by-side/inline,
-- `]c`/`[c` jump between changes, `]f`/`[f` between files, `-` stages a file, `g?` lists every key.

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
  vim.cmd.CodeDiff(base .. '...HEAD')
end

local map = function(lhs, rhs, desc, mode) vim.keymap.set(mode or 'n', lhs, rhs, { desc = desc }) end
map('<leader>gd', '<Cmd>CodeDiff<CR>', '[G]it [D]iff uncommitted changes (review mode)')
map('<leader>gb', review_branch, '[G]it diff [B]ranch against base (PR view)')
map('<leader>gf', '<Cmd>CodeDiff history %<CR>', '[G]it [F]ile history')
map('<leader>gf', ":<C-u>'<,'>CodeDiff history<CR>", '[G]it history of selected lines', 'x')
map('<leader>gl', '<Cmd>CodeDiff history<CR>', '[G]it [L]og (repo history)')

-- [[ GitHub pull requests ]]
require('octo').setup {
  picker = 'telescope',
  -- A bare `:Octo` lists every available action
  enable_builtin = true,
}
-- PR and comment buffers are markdown
vim.treesitter.language.register('markdown', 'octo')

map('<leader>gp', '<Cmd>Octo pr list<CR>', '[G]itHub [P]ull requests')
-- Works from a PR buffer, or from a checked-out branch that has a PR
map('<leader>gr', function() require('octo.reviews').start_or_resume_review() end, '[G]itHub start/resume [R]eview')
map('<leader>gs', '<Cmd>Octo review submit<CR>', '[G]itHub [S]ubmit review')
