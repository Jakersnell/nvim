-- Obsidian-style markdown
--  render-markdown.nvim: renders headings, checkboxes, tables, callouts, code blocks in the buffer
--  obsidian.nvim: [[wikilinks]], backlinks, note search, daily notes
-- https://github.com/MeanderingProgrammer/render-markdown.nvim
-- https://github.com/obsidian-nvim/obsidian.nvim

vim.pack.add {
  'https://github.com/MeanderingProgrammer/render-markdown.nvim',
  'https://github.com/obsidian-nvim/obsidian.nvim',
}

-- [[ Rendering ]]
require('render-markdown').setup {
  file_types = { 'markdown' },
  -- Show raw markdown on the cursor line (like Obsidian's live preview)
  anti_conceal = { enabled = true },
  completions = { blink = { enabled = true } },
  heading = { sign = false, position = 'inline' },
  code = { sign = false, width = 'block', right_pad = 1 },
  checkbox = { enabled = true },
  pipe_table = { preset = 'round' },
}

-- [[ Notes / links ]]
local workspaces = {}
local vault = vim.fn.expand '~/notes'
if vim.fn.isdirectory(vault) == 1 then table.insert(workspaces, { name = 'notes', path = vault }) end
-- Fallback so obsidian features work on any markdown file outside a vault
table.insert(workspaces, {
  name = 'no-vault',
  path = function() return assert(vim.fs.dirname(vim.api.nvim_buf_get_name(0))) end,
  overrides = { notes_subdir = vim.NIL, new_notes_location = 'current_dir', templates = { folder = vim.NIL } },
})

require('obsidian').setup {
  legacy_commands = false,
  workspaces = workspaces,
  -- render-markdown handles the visuals
  ui = { enable = false },
  picker = { name = 'telescope.nvim' },
  daily_notes = { folder = 'daily' },
}

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('custom-markdown', { clear = true }),
  pattern = 'markdown',
  callback = function(ev)
    vim.opt_local.conceallevel = 2
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true

    local map = function(lhs, rhs, desc) vim.keymap.set('n', lhs, rhs, { buffer = ev.buf, desc = desc }) end
    map('<leader>ob', '<cmd>Obsidian backlinks<CR>', '[O]bsidian [B]acklinks')
    map('<leader>of', '<cmd>Obsidian quick_switch<CR>', '[O]bsidian [F]ind note')
    map('<leader>os', '<cmd>Obsidian search<CR>', '[O]bsidian [S]earch notes')
    map('<leader>on', '<cmd>Obsidian new<CR>', '[O]bsidian [N]ew note')
    map('<leader>od', '<cmd>Obsidian today<CR>', '[O]bsidian [D]aily note')
    map('<leader>ol', '<cmd>Obsidian links<CR>', '[O]bsidian [L]inks in note')
    map('<leader>ot', '<cmd>Obsidian toggle_checkbox<CR>', '[O]bsidian [T]oggle checkbox')
    map('<leader>or', '<cmd>RenderMarkdown toggle<CR>', '[O]bsidian toggle [R]ender')
  end,
})
