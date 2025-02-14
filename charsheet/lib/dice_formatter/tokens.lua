local _t = require("charsheet/lib/table_util")

local process_expression
local add_sub_roll

local paren_token = function(value)
  return { type = "paren", value = value }
end
local operator_token = function(value)
  return { type = "operator", value = value }
end

local add_die_token = function(roll, output)
  local result = _t.clone(roll)
  result.type = "roll"

  if roll.original_value then
    result.value = result.original_value
    table.insert(output, paren_token("["))
    table.insert(output, result)
    table.insert(output, { type = "operator", operator_type = "replacement", value = "→" })
    if result.rolls then
      add_sub_roll(result, output)
      result.rolls = nil
    else
      table.insert(output, { type = "number", value = roll.value })
    end
    table.insert(output, paren_token("]"))
    return
  end

  table.insert(output, result)
end

local add_roll_tokens = function(dice, output)
  for i, roll in ipairs(dice.rolls) do
    if i > 1 then
      table.insert(output, operator_token("+"))
    end
    add_die_token(roll, output)
  end
end

local add_math_tokens = function(definition, output)
  for i, child in ipairs(definition.values) do
    if i > 1 then
      table.insert(output, { type = "operator", value = child.operator })
    end
    process_expression(child.value, output)
  end
end

add_sub_roll = function(definition, output)
  table.insert(output, paren_token("("))
  add_roll_tokens(definition, output)
  table.insert(output, paren_token(")"))
end

process_expression = function(definition, output)
  output = output or {}

  if definition.left == "(" then
    table.insert(output, paren_token(definition.left))
  end

  if definition.parser == "addition" or definition.parser == "multiplication" then
    add_math_tokens(definition, output)
  elseif definition.type == "die_roll" then
    add_sub_roll(definition, output)
  elseif definition.type == "number" then
    local value = definition.value * (definition.negate and -1 or 1)
    table.insert(output, { type = "number", value = value })
  end

  if definition.right == ")" then
    table.insert(output, paren_token(definition.right))
  end

  return output
end

return process_expression
