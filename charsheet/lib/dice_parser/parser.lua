local P = {}
local cache = {}
local nil_table = {}

local P_meta = {
  __index = P,
  __call = function(_, name, callback)
    cache[name] = cache[name] or {}

    return function(...)
      local arg_key = ... or nil_table

      if cache[name][arg_key] == nil then
        local parser = callback(...)

        local cached_method = function(str)
          local result = parser(str)
          if result then
            result.parser = name
          end
          return result
        end

        cache[name][arg_key] = cached_method
        return cached_method
      end
      return cache[name][arg_key]
    end
  end
}
setmetatable(P, P_meta)

function P.err(message)
  return {
    err = message
  }
end

local lazyParser = function(parser)
  local p
  return function(str)
    if not p then
      p = parser()
    end

    return p(str)
  end
end

return {
  P = P,
  lazy = lazyParser
}
