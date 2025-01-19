local _t = require("charsheet/lib/table_util")
local P = require("charsheet/lib/dice_parser/parser")
local dump = require("charsheet/lib/dump")

local literal = P("literal", function(chars)
  return function(str)
    local begin_chars = str:sub(1, #chars)
    if begin_chars == chars then
      return {
        value = chars,
        rest = str:sub(#chars + 1)
      }
      --else
      --  return P.err "Expected " .. chars .. ", received " .. begin_chars
    end
  end
end)

local toLiteral = function(parser)
  if type(parser) == "string" then
    return literal(parser)
  end
  return parser
end

local match = P("match", function(pattern)
  -- TODO captures
  pattern = pattern:sub(1, 1) == "^" and pattern or ("^" .. pattern)
  return function(str)
    local start, finish = str:find(pattern)
    if start then
      return {
        value = str:sub(1, finish),
        rest = str:sub(finish + 1)
      }
      --else
      --  return error("Could not find match for pattern " .. pattern)
    end
  end
end)

local any = function(...)
  local parsers = _t.map({ ... }, toLiteral)

  return function(str)
    for _, combinator in ipairs(parsers) do
      local result = combinator(str)

      if result then
        return result
      end
    end
  end
end

local optional = function(parser)
  parser = toLiteral(parser)
  return function(str)
    return parser(str) or {
      rest = str
    }
  end
end

local map = function(combinator, m)
  return function(str)
    local result = combinator(str)
    if result then
      return m(result)
    end
  end
end

local concatenate = function(combinator)
  return map(combinator, function(result)
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

local capture = function(name, key, combinator, m)
  if type(key) == "function" then
    m = combinator
    combinator = key
    key = "value"
  end

  return map(combinator, function(result)
    local r = _t.clone(result)
    r.captures = r.captures and _t.clone(r.captures) or {}
    r.captures[name] = m and m(r[key]) or r[key]
    return r
  end)
end

local captureValues = function(name, combinator)
  return capture(name, "values", combinator)
end


-- TODO: don't need values array, but might require an unpack
local sequence = function(...)
  local combinators = _t.map({ ... }, toLiteral)

  return function(str)
    local rest = str
    local val = {}
    local captures = {}

    for i, combinator in ipairs(combinators) do
      local result = combinator(rest)
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
      --value = table.concat(val, ""),
      values = val,
      rest = rest,
      captures = captures
    }
  end
end

local nOrMore = function(n, combinator)
  combinator = toLiteral(combinator)

  return function(str)
    local rest = str
    local matches = {}

    while true do
      local result = combinator(rest)
      if result then
        table.insert(matches, result)
        rest = result.rest
      else
        break
      end
    end

    if #matches > n then
      return {
        --value = table.concat(matches, ""),
        values = matches,
        rest = rest
      }
    end
  end
end

local nOrMoreUnique = function(n, ...)
  local combinators = _t.map({ ... }, toLiteral)

  return function(str)
    local rest = str
    local results = {}
    local captures = {}

    while rest ~= "" and #combinators > 0 do
      local success = false
      for i, combinator in ipairs(combinators) do
        local combinator_result = combinator(rest)
        if combinator_result then
          rest = combinator_result.rest
          if combinator_result.captures then
            for k, v in pairs(combinator_result.captures) do
              captures[k] = v
            end
          end
          table.insert(results, combinator_result)
          table.remove(combinators, i)
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
        --value = table.concat(values, ""),
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
      r.rest = result.rest
      return r
      --r.value = result.captures.between
      --return r
    end
  )
end


local nthValue = function(n, combinator)
  return map(combinator, function(result)
    if not result then
      return
    end

    local r = _t.clone(result.values[n])
    r.rest = result.rest

    return r
  end)
end

local dropLeftValue = function(n, combinator)
  return map(combinator, function(result)
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

local ignore = function(parser)
  parser = toLiteral(parser)
  return function(str)
    local result = parser(str)
    if result then
      return {
        rest = result.rest
      }
    end
  end
end

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
  captureValues = captureValues,
  concatenate = concatenate,
  dropLeftValue = dropLeftValue,
  ignore = ignore,
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
