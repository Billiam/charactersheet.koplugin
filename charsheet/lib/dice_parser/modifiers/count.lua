local operations = require("charsheet/lib/dice_parser/operations")

return function(die, rolls, _)
  if not die.modifiers.count then
    return
  end

  local total = 0
  local conditions = die.modifiers.count.values
  if #conditions == 0 then
    conditions = { { operator = "=", value = die.sides } }
  end
  for _, roll in ipairs(rolls) do
    for _, condition in ipairs(conditions) do
      if operations.equality[condition.operator](roll.value, condition.value) then
        total = total + 1
        break
      end
    end
  end
  die.count_result = total
end
