-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

vim.pack.add {
  { src = 'https://github.com/nvim-neo-tree/neo-tree.nvim', version = vim.version.range '*' },
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/MunifTanjim/nui.nvim',
}

vim.keymap.set('n', '\\', '<Cmd>Neotree reveal<CR>', { desc = 'NeoTree reveal', silent = true })

-- Expand (expand = true) or collapse (expand = false) the directory under the cursor.
-- Files, and directories already in the requested state, are left alone, and the cursor
-- stays on the same node.
local function set_dir_expanded(expand)
  return function(state)
    local node = state.tree:get_node()
    if not node or node.type ~= 'directory' then return end
    local expanded = node.loaded ~= false and (node:is_expanded() or node.empty_expanded == true)
    if expanded == expand then return end

    local id = node:get_id()
    local renderer = require 'neo-tree.ui.renderer'
    local refocus = function() renderer.focus_node(state, id) end
    require('neo-tree.sources.filesystem').toggle_directory(state, node, nil, false, false, refocus)
    refocus()
  end
end

require('neo-tree').setup {
  filesystem = {
    window = {
      mappings = {
        ['\\'] = 'close_window',
        ['<Left>'] = { set_dir_expanded(true), desc = 'expand directory' },
        ['<Right>'] = { set_dir_expanded(false), desc = 'collapse directory' },
      },
    },
  },
}
