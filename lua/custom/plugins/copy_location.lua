-- Copy a reference to the current line to the system clipboard, as `path:line:function`
-- (for example `src/api/users.ts:42:UserService.create`), for pasting into chats, tickets or prompts.
--
--  path      relative to the git root of the file, else to the working directory
--  line      the cursor line, or `first-last` for a visual selection / command range
--  function  the enclosing class/function names from treesitter; left out when there are none

-- Treesitter node types that are worth naming, across the common grammars
local scope_types = {}
for _, node_type in ipairs {
  -- functions
  'function_declaration',
  'function_definition',
  'function_expression',
  'function_item',
  'generator_function',
  'generator_function_declaration',
  'arrow_function',
  'func_literal',
  'method_declaration',
  'method_definition',
  'method',
  'singleton_method',
  'constructor_declaration',
  -- classes and the like
  'class_declaration',
  'class_definition',
  'class',
  'abstract_class_declaration',
  'class_specifier',
  'interface_declaration',
  'impl_item',
  'trait_item',
  'module',
} do
  scope_types[node_type] = true
end

--- The node holding the name of a function/class node, if it has one.
---@param node TSNode
---@return TSNode?
local function name_node(node)
  local name = node:field('name')[1]
  if name then return name end
  if node:type() == 'impl_item' then return node:field('type')[1] end

  -- C family: the name is nested inside declarators
  local declarator = node:field('declarator')[1]
  while declarator and declarator:field('declarator')[1] do
    declarator = declarator:field('declarator')[1]
  end
  if declarator then return declarator end

  -- Anonymous function: name it after what it is assigned to (`local f = function`, `f: () =>`, ...)
  local parent = node:parent()
  if parent and parent:type() == 'expression_list' then parent = parent:parent() end
  if not parent then return nil end
  for _, field in ipairs { 'name', 'key', 'left', 'property' } do
    local target = parent:field(field)[1]
    if target and target:id() ~= node:id() then return target end
  end
  if parent:type() == 'assignment_statement' then return parent:named_child(0) end
end

--- Names of the classes/functions enclosing a position, outermost first.
---@param buf integer
---@param row integer 0-based
---@param col integer 0-based
---@return string[]
local function scopes_at(buf, row, col)
  local node = vim.treesitter.get_node { bufnr = buf, pos = { row, col }, ignore_injections = false }
  local names = {}
  while node do
    local name = scope_types[node:type()] and name_node(node)
    if name then
      local text = vim.treesitter.get_node_text(name, buf):gsub('^["\'](.*)["\']$', '%1')
      if not text:find '\n' and #text <= 80 then table.insert(names, 1, text) end
    end
    node = node:parent()
  end
  return names
end

--- Names of the classes/functions enclosing a line, joined with `.`.
---@param buf integer
---@param lnum integer 1-based
---@return string?
local function enclosing_scope(buf, lnum)
  local ok, parser = pcall(vim.treesitter.get_parser, buf, nil, { error = false })
  if not ok or not parser then return nil end

  local line = vim.api.nvim_buf_get_lines(buf, lnum - 1, lnum, false)[1] or ''
  parser:parse { lnum - 1, 0, lnum - 1, #line }

  -- Judge the line rather than the cursor column: look at both of its ends and keep the deeper answer,
  -- so that a line which opens a function (`local f = function()`, `export function f() {`) counts as inside it.
  local first_col = (line:find '%S' or 1) - 1
  local last_col = math.max(line:find '%s*$' - 2, 0)
  local names, at_end = scopes_at(buf, lnum - 1, first_col), scopes_at(buf, lnum - 1, last_col)
  if #at_end > #names then names = at_end end
  if #names > 0 then return table.concat(names, '.') end
end

--- Copy `path:line:function` for a line (or line range) of the current buffer to the clipboard.
---@param line1 integer? 1-based, defaults to the cursor line
---@param line2 integer? defaults to line1
local function copy_location(line1, line2)
  local buf = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(buf)
  if path == '' then
    vim.notify('Buffer has no file name to copy', vim.log.levels.WARN)
    return
  end

  line1 = line1 or vim.fn.line '.'
  line2 = line2 or line1
  local root = vim.fs.root(buf, '.git') or vim.fn.getcwd()
  local parts = {
    vim.fs.relpath(root, path) or vim.fn.fnamemodify(path, ':~'),
    line1 == line2 and tostring(line1) or (line1 .. '-' .. line2),
    enclosing_scope(buf, line1),
  }

  local location = table.concat(parts, ':')
  vim.fn.setreg('+', location)
  vim.notify('Copied ' .. location)
end

vim.api.nvim_create_user_command('CopyLocation', function(opts) copy_location(opts.line1, opts.line2) end, {
  range = true,
  desc = 'Copy path:line:function of the current line (or range) to the system clipboard',
})

vim.keymap.set('n', '<leader>yl', '<Cmd>CopyLocation<CR>', { desc = '[Y]ank [L]ocation: copy file path:line:function to clipboard' })
vim.keymap.set('x', '<leader>yl', ':CopyLocation<CR>', { silent = true, desc = '[Y]ank [L]ocation: copy file path:lines:function of selection to clipboard' })
