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

  for _, v in ipairs(t) do
    if v == value then
      return true
    end
  end

  return false
end

return TableUtil
