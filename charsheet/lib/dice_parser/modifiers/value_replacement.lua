local operations = require("charsheet/lib/dice_parser/operations")
local _t = require("charsheet/lib/table_util")

return function(die, rolls, roller)
  if not die.modifiers.value_replacement then
    return
  end

  for _, roll in ipairs(rolls) do
    for _, condition in ipairs(die.modifiers.value_replacement.values) do
      if operations.equality[condition.operator](roll.value, condition.value) then
        roll.original_value = roll.value

        if condition.type == "range" then
          local definition = _t.clone(condition.replacement)
          definition.type = condition.type
          roll.value = roller(definition)
          --FIXME Needs to consider expressions
        elseif condition.type == "die_roll" then
          local definition = _t.clone(condition.replacement)
          definition.type = condition.type
          roll.value = roller(definition, true)
        else
          roll.value = condition.replacement
        end
      end
    end
  end
end
