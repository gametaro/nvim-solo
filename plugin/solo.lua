local solo = require('solo')

if vim.env.NVIM then
  local args = vim.fn.argv(-1)
  local argc = vim.fn.argc(-1)
  local ok, chan = pcall(vim.fn.sockconnect, unpack({ 'pipe', vim.env.NVIM, { rpc = true } }))
  if ok and chan then
    local group = vim.api.nvim_create_augroup('solo', {})

    vim.api.nvim_create_autocmd('StdinReadPost', {
      group = group,
      callback = function()
        if argc == 0 then
          solo.request(
            chan,
            'return require("solo").stdin(...)',
            vim.api.nvim_buf_get_lines(0, 0, -1, false)
          )
        end
      end,
    })

    vim.api.nvim_create_autocmd('UIEnter', {
      group = group,
      callback = function()
        if
          vim.wo.diff and argc <= 3
          -- and vim.iter(args):any(function(arg)
          --   return arg == '-d'
          -- end)
        then
          solo.request(chan, 'return require("solo").diff(...)', args)
        else
          solo.request(chan, 'return require("solo").default(...)', args, vim.v.servername)
        end
      end,
    })
  end
end
