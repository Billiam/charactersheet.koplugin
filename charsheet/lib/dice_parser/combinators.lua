local _t = require("charsheet/lib/table_util")
local NIL = {}

local method_cache = function(builder)
  local cache = {}
  return function(...)
    if not cache[...] then
      cache[...] = builder(...)
    end
    return cache[...]
  end
end

local cache = function(parser)
  local cache = {}
  return function(str)
    if not cache[str] then
      local result = parser(str)
      cache[str] = result or NIL
      return result
    end

    local result = cache[str]
    if result ~= NIL then
      return result
    end
  end
end

local map = function(parser, m)
  return function(str)
    local result = parser(str)
    if result then
      return m(result)
    end
  end
end

local label = function(name, parser)
  return function(str)
    local result = parser(str)
    if result then
      result.parser = name
    end

    return result
  end
end

local literal = method_cache(function(chars)
  return cache(label("literal", function(str)
    local begin_chars = str:sub(1, #chars)
    if begin_chars == chars then
      return {
        value = chars,
        rest = str:sub(#chars + 1)
      }
    end
  end))
end)

local toLiteral = function(parser)
  if type(parser) == "string" then
    return literal(parser)
  end
  return parser
end

local match = method_cache(function(pattern)
  -- TODO captures
  pattern = pattern:sub(1, 1) == "^" and pattern or ("^" .. pattern)

  return label("match", function(str)
    local start, finish = str:find(pattern)
    if start then
      return {
        value = str:sub(1, finish),
        rest = str:sub(finish + 1)
      }
      --else
      --  return error("Could not find match for pattern " .. pattern)
    end
  end)
end)

local any = function(...)
  local parsers = _t.map({ ... }, toLiteral)

  return function(str)
    for _, parser in ipairs(parsers) do
      local result = parser(str)

      if result then
        if result.type then
          return result
        else
          local r = _t.clone(result)
          r.type = r.parser
          return r
        end
      end
    end
  end
end

local optional = method_cache(function(parser)
  parser = toLiteral(parser)
  return cache(function(str)
    return parser(str) or {
      rest = str
    }
  end)
end)

local concatenate = function(parser)
  return map(parser, function(result)
    local r = _t.clone(result)
    local values = {}
    for _, v in ipairs(result.values) do
      if v.value ~= nil then
        table.insert(values, v.value)
      end
    end
    r.value = table.concat(values, "")
    r.values = nil
    return r
  end)
end

local capture = function(name, key, parser, m)
  if type(key) == "function" then
    m = parser
    parser = key
    key = "value"
  end

  return map(parser, function(result)
    local r = _t.clone(result)
    r.captures = r.captures and _t.clone(r.captures) or {}
    r.captures[name] = m and m(r[key]) or r[key]
    return r
  end)
end

local captureValues = function(name, parser)
  return capture(name, "values", parser)
end

-- TODO: don't need values array, but might require an unpack
local sequence = function(...)
  local parsers = _t.map({ ... }, toLiteral)

  return function(str)
    local rest = str
    local val = {}
    local captures = {}

    for i, parser in ipairs(parsers) do
      local result = parser(rest)
      if not result then
        return
      end

      rest = result.rest
      val[i] = result

      for k, v in pairs(result.captures or {}) do
        captures[k] = v
      end
    end

    return {
      values = val,
      rest = rest,
      captures = captures
    }
  end
end

local nOrMore = function(n, parser)
  parser = toLiteral(parser)

  return function(str)
    local rest = str
    local matches = {}

    while true do
      local result = parser(rest)
      if result then
        table.insert(matches, result)
        rest = result.rest
      else
        break
      end
    end

    if #matches >= n then
      return {
        --value = table.concat(matches, ""),
        values = matches,
        rest = rest
      }
    end
  end
end

local nOrMoreUnique = function(n, ...)
  local parser_list = _t.map({ ... }, toLiteral)

  return function(str)
    local parsers = _t.clone(parser_list)

    local rest = str
    local results = {}
    local captures = {}

    while rest ~= "" and #parsers > 0 do
      local success = false
      for i, parser in ipairs(parsers) do
        local parser_result = parser(rest)
        if parser_result then
          rest = parser_result.rest
          if parser_result.captures then
            for k, v in pairs(parser_result.captures) do
              captures[k] = v
            end
          end
          table.insert(results, parser_result)
          table.remove(parsers, i)
          success = true

          break
        end
      end

      if not success then
        break
      end
    end

    if #results >= n then
      return {
        values = results,
        captures = captures,
        rest = rest
      }
    end
  end
end

local between = function(left, right, middle)
  left = toLiteral(left)
  right = toLiteral(right)
  return map(
    sequence(left, middle, right),
    function(result)
      local r = _t.clone(result.values[2])
      r.left = result.values[1].value
      r.right = result.values[3].value
      r.rest = result.rest
      return r
    end
  )
end

local nthValue = function(n, parser)
  return map(parser, function(result)
    if not result then
      return
    end

    local r = _t.clone(result.values[n])
    r.rest = result.rest

    return r
  end)
end

local dropLeftValue = function(n, parser)
  return map(parser, function(result)
    if not result then
      return
    end
    local values = {}
    for i, v in ipairs(result.values) do
      if i > n then
        values[i - n] = v
      end
    end
    local r = _t.clone(result)
    r.values = values

    return r
  end)
end

local ignore = method_cache(function(parser)
  parser = toLiteral(parser)
  return function(str)
    local result = parser(str)
    if result then
      return {
        rest = result.rest
      }
    end
  end
end)

local list = function(separator, parser)
  separator = toLiteral(separator)
  parser = toLiteral(parser)

  return map(
    sequence(
      parser,
      optional(nOrMore(0, nthValue(2, sequence(separator, parser)))),
      optional(separator)
    ),
    function(result)
      local values = { result.values[1] }

      if _t.dig(result.values, 2, "values") then
        for i, v in ipairs(result.values[2].values) do
          values[i + 1] = v
        end
      end

      result.values = values
      return result
    end
  )
end

-- FIXME this will always break error location
local stripWhitespace = function()
  return function(str)
    return {
      rest = str:gsub("%s", "")
    }
  end
end

local skipWhitespace = function()
  return ignore(match("^%s+"))
end

return {
  any = any,
  between = between,
  capture = capture,
  cache = cache,
  captureValues = captureValues,
  concatenate = concatenate,
  dropLeftValue = dropLeftValue,
  ignore = ignore,
  label = label,
  list = list,
  literal = literal,
  map = map,
  match = match,
  nthValue = nthValue,
  nOrMore = nOrMore,
  nOrMoreUnique = nOrMoreUnique,
  optional = optional,
  sequence = sequence,
  stripWhitespace = stripWhitespace,
}
