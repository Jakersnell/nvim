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
-- `]c`/`[c` jump between diff chunks, `]f`/`[f` between files, `-` stages a file, `g?` lists every key.

-- The review keys are buffer-local to the review tab (codediff's defaults, unchanged); list them in
-- `<leader>sk` from anywhere. Read from codediff's live config so a remap stays in sync.
require('custom.keymap_search').add_scoped {
  scope = 'codediff',
  hint = 'inside a diff review (<leader>gd uncommitted, <leader>gb branch/PR, <leader>gf/<leader>gl history)',
  active = function()
    return require('codediff.ui.lifecycle').get_session(vim.api.nvim_get_current_tabpage()) ~= nil
  end,
  keys = function()
    local km = require('codediff.config').options.keymaps
    local v, e, h, c = km.view, km.explorer, km.history, km.conflict
    local n, ox = { 'n' }, { 'o', 'x' }
    local keys = {
      -- Diff panes
      { n, v.next_hunk, 'Diff review: next diff chunk (hunk / change)' },
      { n, v.prev_hunk, 'Diff review: previous diff chunk (hunk / change)' },
      { ox, v.hunk_textobject, 'Diff review: select diff chunk text object (vih select, yih yank)' },
      { n, v.next_file, 'Diff review: next diff file' },
      { n, v.prev_file, 'Diff review: previous diff file' },
      { n, v.quit, 'Diff review: close the review tab' },
      { n, v.toggle_layout, 'Diff review: toggle side-by-side / inline layout' },
      { n, v.toggle_compact, 'Diff review: toggle compact mode (fold unchanged lines)' },
      { n, v.toggle_explorer, 'Diff review: show/hide the file list (explorer)' },
      { n, v.focus_explorer, 'Diff review: focus the file list (explorer)' },
      { n, v.open_in_prev_tab, 'Diff review: open this file in a normal tab to edit' },
      { n, v.align_move, 'Diff review: align the other pane to show moved code' },
      { n, v.diff_get, 'Diff review: get diff chunk from the other side (diffget)' },
      { n, v.diff_put, 'Diff review: put diff chunk to the other side (diffput)' },
      { n, v.toggle_stage, 'Diff review: git stage/unstage the current file' },
      { n, v.toggle_staged_view, 'Diff review: switch between staged and unstaged view of file' },
      { n, v.stage_hunk, 'Diff review: git stage the diff chunk under the cursor' },
      { n, v.unstage_hunk, 'Diff review: git unstage the diff chunk under the cursor' },
      { n, v.discard_hunk, 'Diff review: discard the diff chunk under the cursor (working tree)' },
      { n, v.show_help, 'Diff review: show every review key (help)' },
      -- File list (explorer) and history panels; keys they share are listed once
      { n, e.select, 'Diff file list / history: open the selected file or commit' },
      { n, e.hover, 'Diff file list: show file details' },
      { n, e.refresh, 'Diff file list / history: refresh' },
      { n, e.toggle_view_mode, 'Diff file list / history: toggle list / tree view' },
      { n, e.stage_all, 'Diff file list: git stage all files' },
      { n, e.unstage_all, 'Diff file list: git unstage all files' },
      { n, e.restore, 'Diff file list: discard changes to the file (restore)' },
      { n, e.toggle_changes, 'Diff file list: show/hide the unstaged changes group' },
      { n, e.toggle_staged, 'Diff file list: show/hide the staged changes group' },
      { n, e.fold_open, 'Diff file list / history: open folder (fold)' },
      { n, e.fold_open_recursive, 'Diff file list / history: open folder and subfolders (fold)' },
      { n, e.fold_close, 'Diff file list / history: close folder (fold)' },
      { n, e.fold_close_recursive, 'Diff file list / history: close folder and subfolders (fold)' },
      { n, e.fold_toggle, 'Diff file list / history: toggle folder (fold)' },
      { n, e.fold_toggle_recursive, 'Diff file list / history: toggle folder and subfolders (fold)' },
      { n, e.fold_open_all, 'Diff file list / history: open all folders (fold)' },
      { n, e.fold_close_all, 'Diff file list / history: close all folders (fold)' },
      { n, h.select, 'Diff history: open the selected commit or file' },
      { n, h.refresh, 'Diff history: refresh commits' },
      { n, h.toggle_view_mode, 'Diff history: toggle list / tree view' },
      -- Merge conflict view
      { n, c.next_conflict, 'Merge conflict: next conflict' },
      { n, c.prev_conflict, 'Merge conflict: previous conflict' },
      { n, c.accept_incoming, 'Merge conflict: accept incoming (theirs)' },
      { n, c.accept_current, 'Merge conflict: accept current (ours)' },
      { n, c.accept_both, 'Merge conflict: accept both' },
      { n, c.discard, 'Merge conflict: discard both, keep base' },
      { n, c.accept_all_incoming, 'Merge conflict: accept ALL incoming (theirs) in file' },
      { n, c.accept_all_current, 'Merge conflict: accept ALL current (ours) in file' },
      { n, c.accept_all_both, 'Merge conflict: accept ALL both in file' },
      { n, c.discard_all, 'Merge conflict: discard ALL, reset file to base' },
      { n, c.diffget_incoming, 'Merge conflict: get diff chunk from incoming (theirs)' },
      { n, c.diffget_current, 'Merge conflict: get diff chunk from current (ours)' },
    }
    local out, seen = {}, {}
    for _, k in ipairs(keys) do
      -- An action can be disabled (false) or bound to several keys
      local lhss = type(k[2]) == 'table' and k[2] or { k[2] }
      for _, mode in ipairs(k[1]) do
        for _, lhs in ipairs(lhss) do
          if type(lhs) == 'string' and lhs ~= '' and not seen[mode .. lhs] then
            seen[mode .. lhs] = true
            table.insert(out, { mode, lhs, k[3] })
          end
        end
      end
    end
    return out
  end,
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
