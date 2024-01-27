local M = {}

function M.wait()
  local interrupted = false
  while not interrupted do
    local ok, msg = pcall(vim.fn.getchar)
    if not ok and msg == 'Keyboard interrupt' then
      interrupted = true
    end
  end
end

---@param chan integer
---@param code string
---@param ... unknown
function M.request(chan, code, ...)
  local result = vim.rpcrequest(chan, 'nvim_exec_lua', code, { ... })
  if result == vim.NIL then
    vim.cmd.quitall({ bang = true })
  end
  vim.fn.chanclose(chan)
  M.wait()
end

---@param address string
function M.close(address)
  local ok, chan = pcall(vim.fn.sockconnect, unpack({ 'pipe', address, { rpc = true } }))
  if not ok then
    return
  end
  vim.rpcnotify(chan, 'nvim_exec_lua', 'vim.cmd.qall({ bang = true })', {})
  vim.fn.chanclose(chan)
end

---@param args string[]
---@param address string
function M.default(args, address)
  if #args ~= 0 then
    vim.cmd.drop({ args = args, mods = { tab = 1 } })

    if vim.bo.filetype == 'gitcommit' then
      vim.api.nvim_create_autocmd({ 'QuitPre' }, {
        buffer = vim.api.nvim_get_current_buf(),
        once = true,
        callback = function()
          M.close(address)
        end,
      })
      return true
    end
  end
end

---@param args string[]
function M.diff(args)
  local cmd = string.match(vim.o.diffopt, 'horizontal') and 'split' or 'vsplit'
  for i, file in ipairs(args) do
    if i == 1 then
      vim.cmd.drop({ file, mods = { tab = 1 } })
    elseif i == 2 then
      vim.cmd[cmd]({ file, mods = { split = 'botright' } })
    elseif i == 3 then
      vim.cmd[cmd]({ file, mods = { split = 'botright' } })
    end
    vim.cmd.diffthis()
  end
end

---@param lines string[]
function M.stdin(lines)
  vim.cmd.drop({ '[Stdin]', mods = { tab = 1 } })
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.bo.readonly = true
  vim.bo.modified = false
  vim.bo.buftype = 'nofile'
  vim.cmd.filetype('detect')
end

return M
