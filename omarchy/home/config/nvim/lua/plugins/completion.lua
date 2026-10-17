return {
  {
    'saghen/blink.cmp',
    opts = {
      completion = {
        menu = { auto_show = true },
        list = {
          selection = {
            preselect = false,
            auto_insert = false,
          },
        },
      },
      keymap = {
        preset = 'enter',
        ['<CR>'] = { 'accept', 'fallback' },
        ['<C-e>'] = { 'cancel', 'fallback' },
      },
    },
  },
}
