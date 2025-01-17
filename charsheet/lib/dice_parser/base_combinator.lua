local _t = require("charsheet/lib/table_util")

local literal = function(chars)
  return function(str)
    if str:sub(1, #chars) == chars then
      return {
        value = chars,
        rest = str:sub(#chars + 1)
      }
    end
  end
end

local match = function(pattern)
  -- TODO captures
  pattern = pattern:sub(1, 1) == "^" and pattern or ("^" .. pattern)
  return function(str)
    local start, finish = str:find(pattern)
    if start then
      return {
        value = str:sub(1, finish),
        rest = str:sub(finish + 1)
      }
    end
  end
end

local any = function(...)
  return function(str)
    for _, combinator in ipairs(arg) do
      local result = combinator(str)
      if result then
        result.any_match = combinator
        return result
      end
    end
  end
end

local optional = function(combinator)
  return function(str)
    -- TODO: returning an empty string is awkward
    return combinator(str) or {
      value = "",
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


local sequence = function(...)
  local combinators = { ... }

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
      val[i] = result.value

      for k, v in pairs(result.captures or {}) do
        captures[k] = v
      end
    end

    return {
      value = table.concat(val, ""),
      values = val,
      rest = rest,
      captures = captures
    }
  end
end

local nOrMore = function(n, combinator)
  return function(str)
    local rest = str
    local matches = {}

    while true do
      local result = combinator(rest)
      if result then
        table.insert(matches, result.value)
        rest = result.rest
      else
        break
      end
    end

    if #matches > n then
      return {
        value = table.concat(matches, ""),
        values = matches,
        rest = rest
      }
    end
  end
end

local nOrMoreUnique = function(n, ...)
  local combinators = { ... }

  return function(str)
    local rest = str
    local values = {}

    while rest ~= "" and #combinators > 0 do
      local any_combinator = any(table.unpack(combinators))
      local result = any_combinator(rest)
      if result then
        table.insert(values, result.value)
        rest = result.rest

        local match_index = _t.find(combinators, result.any_match)
        table.remove(combinators, match_index)
      else
        break
      end
    end

    if #values >= n then
      return {
        value = table.concat(values, ""),
        values = values,
        rest = rest
      }
    end
  end
end

local between = function(left, right, middle)
  return map(
    sequence(left, capture("between", middle), right),
    function(result)
      -- TODO: do captures need to be passed?
      return {
        value = result.captures.between,
        rest = result.rest
      }
    end
  )
end


local nthValue = function(n, combinator)
  return map(combinator, function(result)
    if not result then
      return
    end

    local r = _t.clone(result)
    r.value = r.values[n]
    return r
  end)
end

local ignore = function(combinator)
  return function(str)
    local result = combinator(str)
    if result then
      return {
        value = "",
        rest = result.rest
      }
    end
  end
end

local list = function(separator, comparator)
  return map(
    sequence(
      comparator,
      optional(captureValues("list_items", nOrMore(0, sequence(ignore(separator), comparator)))),
      optional(ignore(separator))
    ),
    function(result)
      local values = { result.values[1] }
      if result.captures and result.captures.list_items then
        for i, v in ipairs(result.captures.list_items) do
          values[i + 1] = v
        end
      end

      result.values = values
      return result
    end
  )
end

local stripWhitespace = function()
  return function(str)
    return {
      value = "",
      rest = str:gsub("%s", "")
    }
  end
end

return {
  any = any,
  between = between,
  capture = capture,
  captureValues = captureValues,
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
