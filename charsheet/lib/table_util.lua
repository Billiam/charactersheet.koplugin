local TableUtil = {}

function TableUtil.clone(t, deep)
  local result = {}
  for k, v in pairs(t) do
    if deep and type(v) == "table" then
      result[k] = TableUtil.clone(v, true)
    else
      result[k] = v
    end
  end
  return result
end

function TableUtil.dig(t, ...)
  local result = t

  for _, k in ipairs({ ... }) do
    result = result[k]
    if result == nil then
      return nil
    end
  end

  return result
end

function TableUtil.contains(t, value)
  if not t then
    return false
  end

  return TableUtil.find(t, value) ~= nil
end

function TableUtil.find(t, value, map)
  for i, v in ipairs(t) do
    if map then
      v = map(v)
    end
    if value == v then
      return i
    end
  end
end

local function dump(value, call_indent)
  if not call_indent then
    call_indent = ""
  end

  local indent = call_indent .. "  "

  local output = ""

  if type(value) == "table" then
    output = output .. "{"
    local first = true
    for inner_key, inner_value in pairs(value) do
      if not first then
        output = output .. ", "
      else
        first = false
      end
      output = output .. "\n" .. indent

      local child
      if type(inner_value) == "string" then
        child = "'" .. inner_value .. "'"
      else
        child = dump(inner_value, indent)
      end
      output = output .. inner_key .. " = " .. tostring(child)
    end
    output = output .. "\n" .. call_indent .. "}"
  elseif type(value) == "userdata" then
    output = "userdata"
  elseif type(value) == "function" then
    output = "function()"
  else
    output = value
  end
  return output
end

function TableUtil.dump(table, print_output)
  if print_output == false then
    return dump(table)
  end

  print(dump(table))
end

function TableUtil.map(t, cb)
  local result = {}
  for i, v in ipairs(t) do
    result[i] = cb(v, i)
  end
  return result
end

return TableUtil
