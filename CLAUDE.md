# Neovim config

## Keymaps
- Every keymap must have a `desc`, so it is searchable in the `<leader>sk` picker (`lua/custom/keymap_search.lua`) and shown by which-key.
- Write the `desc` so it can be found by plain words for what the key does (for example "git", "diff", "review"), not only by its mnemonic letters.
- When adding a new `<leader>` prefix, register its group name in the which-key `spec` in `init.lua`.
- When a plugin defines its own keymaps, check that they carry descriptions; add them if they don't.
