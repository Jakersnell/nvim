-- Telescope picker that searches both your keymaps and Neovim's built-in commands.
--
-- Built-in commands (e.g. `dd`, `ciw`, `CTRL-W s`, `zz`, `:substitute`) are not keymaps, so
-- `telescope.builtin.keymaps` can't see them. They are documented in `:help index`, which is
-- parsed here.
--
-- <CR> on a keymap runs it (like telescope's keymaps picker); on a built-in it opens its help.

local M = {}

-- Section headings in index.txt -> short mode label
local sections = {
  { pattern = '^1%. Insert mode', mode = 'i' },
  { pattern = '^2%. Normal mode', mode = 'n' },
  { pattern = '^2%.1 Text objects', mode = 'o' },
  { pattern = '^2%.2 Window commands', mode = 'n' },
  { pattern = '^2%.3 Square bracket', mode = 'n' },
  { pattern = "^2%.4 Commands starting with 'g'", mode = 'n' },
  { pattern = "^2%.5 Commands starting with 'z'", mode = 'n' },
  { pattern = '^2%.6 Operator%-pending mode', mode = 'o' },
  { pattern = '^3%. Visual mode', mode = 'x' },
  { pattern = '^4%. Command%-line editing', mode = 'c' },
  { pattern = '^5%. Terminal mode', mode = 't' },
  { pattern = '^6%. EX commands', mode = ':' },
}

local builtin_cache

--- Parse $VIMRUNTIME/doc/index.txt into { mode, lhs, desc, tag } entries.
local function builtin_commands()
  if builtin_cache then return builtin_cache end

  local path = vim.fs.joinpath(vim.env.VIMRUNTIME, 'doc', 'index.txt')
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then return {} end

  local results, mode, last = {}, nil, nil
  for _, line in ipairs(lines) do
    local new_mode
    for _, s in ipairs(sections) do
      if line:match(s.pattern) then new_mode = s.mode end
    end

    if new_mode then
      mode, last = new_mode, nil
    elseif mode then
      local tag, rest = line:match '^|([^|]+)|\t+(.*)$'
      if tag then
        -- "<keys>\t+<note?><description>"; the note column is "1", "2" or blank
        local lhs, desc = rest:match '^(.-)\t+(.*)$'
        lhs = vim.trim(lhs or rest)
        desc = vim.trim((desc or ''):gsub('^[12]?%s+', ''))
        last = { mode = mode, lhs = lhs, desc = desc, tag = tag }
        table.insert(results, last)
      elseif last and line:match '^\t\t\t' then
        -- Wrapped description
        last.desc = vim.trim(last.desc .. ' ' .. vim.trim(line))
      else
        last = nil
      end
    end
  end

  builtin_cache = results
  return results
end

--- Keymaps currently defined (global + current buffer).
local function user_keymaps()
  local results, seen = {}, {}
  local buf = vim.api.nvim_get_current_buf()
  for _, mode in ipairs { 'n', 'i', 'c', 'x', 'o', 't' } do
    local maps = vim.list_extend(vim.api.nvim_buf_get_keymap(buf, mode), vim.api.nvim_get_keymap(mode))
    for _, map in ipairs(maps) do
      local key = mode .. map.lhs
      if not seen[key] and not map.lhs:find '<Plug>' then
        seen[key] = true
        local lhs = map.lhs:gsub(vim.pesc(vim.g.mapleader or '\\'), '<leader>')
        table.insert(results, {
          mode = mode,
          lhs = lhs,
          raw_lhs = map.lhs,
          desc = map.desc or map.rhs or '',
          keymap = true,
        })
      end
    end
  end
  return results
end

function M.pick(opts)
  opts = opts or {}
  local pickers = require 'telescope.pickers'
  local finders = require 'telescope.finders'
  local conf = require('telescope.config').values
  local actions = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'
  local entry_display = require 'telescope.pickers.entry_display'

  local items = vim.list_extend(user_keymaps(), builtin_commands())

  local displayer = entry_display.create {
    separator = ' ',
    items = { { width = 1 }, { width = 8 }, { width = 20 }, { remaining = true } },
  }

  pickers
    .new(opts, {
      prompt_title = 'Keymaps + Built-in Commands',
      finder = finders.new_table {
        results = items,
        entry_maker = function(item)
          return {
            value = item,
            ordinal = table.concat({ item.mode, item.lhs, item.desc }, ' '),
            display = function(entry)
              local v = entry.value
              return displayer {
                v.mode,
                { v.keymap and 'keymap' or 'builtin', v.keymap and 'TelescopeResultsIdentifier' or 'TelescopeResultsComment' },
                v.lhs,
                v.desc,
              }
            end,
          }
        end,
      },
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if not selection then return end
          local v = selection.value
          if v.keymap then
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(v.raw_lhs, true, false, true), 't', true)
          else
            vim.cmd.help(vim.fn.escape(v.tag, ' '))
          end
        end)
        return true
      end,
    })
    :find()
end

return M
