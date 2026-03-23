--
-- Packed: a single file, somewhat compatible Packer replacement
-- Written by grace
--

local function resolve_src(s)
  if s:match("^https?://") then
    return s
  end
  if s:match("^[%w%-]+/[%w%-_.]+$") then
    return "https://github.com/" .. s
  end
  return s
end

local function normalize_plugin(p)
  if type(p) == "string" then
    return {
      src = resolve_src(p),
      name = p:match(".*/(.*)"),
    }
  end

  if type(p[1]) == "string" then
    p.src = resolve_src(p[1])
    p[1] = nil
  end

  if p.src then
    p.src = resolve_src(p.src)
  end

  if not p.name and p.as then
    p.name = p.as
  end

  if not p.version then
    if p.commit then
      p.version = p.commit
    elseif p.tag then
      p.version = p.tag
    elseif p.branch then
      p.version = p.branch
    end
  end



  local unsupported = {
    'disable', 'installer', 'updater', 'after', 'rtp',
    'opt', 'bufread', 'lock', 'run', 'requires', 'rocks', 'setup'
  }

  for _, field in ipairs(unsupported) do
    if p[field] then
      vim.notify("Packed does not support `" .. field .. "`: " .. (p.name or p.src), vim.log.levels.WARN)
      vim.api.nvim_echo({ { "Press Enter to continue...", "MoreMsg" } }, false, {})
      vim.fn.getchar()
    end
  end

  if p.cmd or p.ft or p.keys or p.event or p.fn or p.cond or p.module or p.module_pattern then
    vim.notify("Packed does not support lazy loading: " .. (p.name or p.src), vim.log.levels.WARN)
    vim.api.nvim_echo({ { "Press Enter to continue...", "MoreMsg" } }, false, {})
    vim.fn.getchar()
  end



  return p
end

local function setup_plugins(plugs)
  local plugins = {}

  if type(plugs) == "function" then
    local function use(p)
      table.insert(plugins, p)
    end

    plugs(use)
  else
    plugins = plugs
  end
  local specs = {}

  for _, p in ipairs(plugins) do
    p = normalize_plugin(p)

    local spec = vim.deepcopy(p)
    spec.config = nil

    table.insert(specs, spec)
  end

  vim.pack.add(specs, { confirm = true, load = true })


  for _, p in ipairs(plugins) do
    if type(p) ~= "string" and p.config then
      local ok = pcall(p.config)
      if not ok then
        vim.notify("Config failed: " .. (p.name or p.src), vim.log.levels.ERROR)
        vim.api.nvim_echo({ { "Press Enter to continue...", "MoreMsg" } }, false, {})
        vim.fn.getchar()
      end
    end
  end


  local unused = vim.iter(vim.pack.get())
      :filter(function(p)
        return not p.active
      end)
      :map(function(p)
        return p.spec.name
      end)
      :totable()

  vim.pack.del(unused)
end


local r = {}
r.setup = setup_plugins

return r
