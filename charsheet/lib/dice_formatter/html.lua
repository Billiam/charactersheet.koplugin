local tokenFormatter = require("charsheet/lib/dice_formatter/tokens")
local _t = require("charsheet/lib/table_util")

local span = function(class, text)
  return "<span class='" .. class .. "'>" .. tostring(text):gsub(">", "&gt;"):gsub(">", "&lt;") .. "</span>"
end

local css = [[
@page {
  margin: 0;
  padding: 0;
  font-family: 'Noto Sans';
}
html,body {
  margin: 0;
  padding: 0;
}
.dice {
  padding: 0;
  margin:0;
  white-space: break-all;
  overflow-wrap: anywhere;
}
.drop {
  text-decoration: line-through;
  color: #ccc;
}
.operator {
  color: #888;
}
.exploded {
  font-weight: bold;
}
]]

return function(definition)
  local tokens = tokenFormatter(definition)

  local values = _t.map(tokens, function(token)
    local class = token.type
    local value = token.value

    if token.type == "roll" then
      if token.exploded then
        class = class .. " exploded"
      end

      if token.drop or token.original_value then
        class = class .. " drop"
      end
    end

    return span(class, value)
  end)

  return {
    value = "<p class='dice'>" .. table.concat(values, "&#8203;") .. "</p>",
    css = css
  }
end
