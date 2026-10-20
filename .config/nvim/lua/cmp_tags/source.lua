-- cmp source that completes from the ctags files listed in the 'tags' option.
-- Project tags are produced by vim-gutentags; the default 'tags' value
-- ("./tags;,tags") already searches upwards, so no per-project setup is needed.
local CompletionItemKind = require("cmp.types.lsp").CompletionItemKind

local defaults = {
  keyword_length = 2, -- characters typed before the tags file is queried
  max_items = 100, -- cap on candidates handed to the menu
  cache_ttl_ms = 2000, -- reuse a taglist() result for this long
}

-- ctags kind letters are language specific; map the common ones and fall back
-- to Reference so tag entries stay distinguishable from buffer entries (Text).
local KIND = {
  a = CompletionItemKind.Variable,
  c = CompletionItemKind.Class,
  C = CompletionItemKind.Constant,
  d = CompletionItemKind.Macro,
  e = CompletionItemKind.Enum,
  f = CompletionItemKind.Function,
  F = CompletionItemKind.Field,
  g = CompletionItemKind.EnumMember,
  i = CompletionItemKind.Interface,
  l = CompletionItemKind.Variable,
  m = CompletionItemKind.Method,
  M = CompletionItemKind.Module,
  n = CompletionItemKind.Namespace,
  o = CompletionItemKind.Variable,
  p = CompletionItemKind.Property,
  s = CompletionItemKind.Struct,
  S = CompletionItemKind.Method, -- ruby: singleton method
  t = CompletionItemKind.TypeParameter,
  v = CompletionItemKind.Variable,
}

local source = {}

source.new = function()
  local self = setmetatable({}, { __index = source })
  self.probe = nil -- { at = uv.now(), result = boolean }
  self.cache = nil -- { key = prefix, at = uv.now(), tags = taglist() result }
  return self
end

local function options(params)
  return vim.tbl_deep_extend("keep", params.option or {}, defaults)
end

local function find_tags(prefix)
  -- taglist() takes a Vim regexp against the tag name; escape the typed prefix.
  local ok, tags = pcall(vim.fn.taglist, "^" .. vim.fn.escape(prefix, [[\/.*$^~[]]))
  if not ok or type(tags) ~= "table" then
    return {}
  end
  return tags
end

source.get_keyword_pattern = function()
  return [[\k\+]]
end

-- Only offer the source when a tags file is actually readable; the probe is
-- cached briefly because this is called on every completion.
source.is_available = function(self)
  local now = vim.uv.now()
  if self.probe and now - self.probe.at < 2000 then
    return self.probe.result
  end

  local available = false
  for _, entry in ipairs(vim.split(vim.o.tags, ",", { trimempty = true })) do
    local path = vim.fn.expand(entry:gsub(";.*$", ""))
    if path ~= "" and path ~= "tags" and vim.fn.filereadable(path) == 1 then
      available = true
      break
    end
  end
  if not available then
    available = #find_tags("a") > 0 -- "./tags;" style upward search
  end

  self.probe = { at = now, result = available }
  return available
end

-- taglist() scans every tag name, which costs ~20ms on a 200k-entry tags file,
-- and cmp calls this on each keystroke: reuse the last result for a moment.
-- Only the taglist() output is cached and truncated; item tables are rebuilt on
-- every call so cmp always gets fresh tables.
source._tags_for = function(self, prefix, ttl)
  local now = vim.uv.now()
  local cache = self.cache
  if cache and cache.key == prefix and now - cache.at <= ttl then
    return cache.tags
  end

  local tags = find_tags(prefix)
  local truncated = {}
  for i = 1, math.min(#tags, 500) do
    truncated[i] = tags[i]
  end
  self.cache = { key = prefix, at = now, tags = truncated }
  return truncated
end

source.complete = function(self, params, callback)
  local opts = options(params)
  local input = string.sub(params.context.cursor_before_line, params.offset)

  if #input < opts.keyword_length then
    return callback({ items = {} })
  end

  local items, seen = {}, {}
  for _, tag in ipairs(self:_tags_for(input, opts.cache_ttl_ms)) do
    local name = tag.name
    if name and name ~= "" and name ~= input and not seen[name] then
      seen[name] = true

      local detail = tag.filename or ""
      if tag.scope then
        detail = detail .. " (" .. tag.kind .. " in " .. tag.scope .. ")"
      end

      items[#items + 1] = {
        label = name,
        word = name, -- cmp reads word before label in some paths
        insertText = name,
        filterText = name,
        kind = KIND[tag.kind] or CompletionItemKind.Reference,
        detail = detail,
        documentation = {
          kind = "plaintext",
          value = table.concat(vim.tbl_filter(function(line)
            return line ~= nil and line ~= ""
          end, {
            "tag: " .. name,
            "kind: " .. (tag.kind or "?"),
            "file: " .. (tag.filename or "?"),
            "search: " .. (tag.cmd or "?"),
            tag.scope and ("scope: " .. tag.scope) or nil,
          }), "\n"),
        },
      }

      if #items >= opts.max_items then
        break
      end
    end
  end

  callback({ items = items, isIncomplete = false })
end

return source
