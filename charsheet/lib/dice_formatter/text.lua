local tokenFormatter = require("charsheet/lib/dice_formatter/tokens")
local _t = require("charsheet/lib/table_util")

return function(definition)
  local tokens = tokenFormatter(definition)

  local values = _t.map(tokens, function(token)
    if token.type == "roll" then
      local value = token.value
      if token.exploded then
        value = value .. "!"
      end

      if token.drop then
        local chars = {}
        local i = 1
        for num in tostring(value):gmatch('%d') do
          chars[i] = num
          chars[i + 1] = "̵"
          i = i + 2
        end
        value = "̵" .. table.concat(chars, "")
      end

      return value
    else
      return token.value
    end
  end)

  return table.concat(values, "")
end
