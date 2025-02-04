local tokenFormatter = require("charsheet/lib/dice_formatter/tokens")
local color = require("charsheet/lib/terminal_colors")
local _t = require("charsheet/lib/table_util")

return function(definition)
  local tokens = tokenFormatter(definition)

  local values = _t.map(tokens, function(token)
    if token.type == "roll" then
      local value = token.value
      if token.exploded then
        value = color.bold(value)
      end
      if token.drop then
        value = color.strike(value)
      end
      if token.original_value or token.drop then
        value = color.black(value)
      end
      return value
    elseif token.type == "paren" then
      return color.blue(token.value)
    elseif token.type == "operator" then
      return color.cyan(token.value)
    else
      return color.green(token.value)
    end
  end)

  return table.concat(values, "")
end
