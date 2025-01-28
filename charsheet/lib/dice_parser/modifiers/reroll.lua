local operations = require("charsheet/lib/dice_parser/operations")

local shouldReroll = function(roll, reroll_index, range_conditions)
  if reroll_index[roll.value] then
    return true
  end

  for _, condition in ipairs(range_conditions) do
    if operations.equality[condition.operator](roll.value, condition.value) then
      return true
    end
  end

  return false
end

return function(die, rolls, roller)
  if not die.modifiers.reroll then
    return
  end

  local range_conditions = {}
  local reroll_index = {}

  for _, condition in ipairs(die.modifiers.reroll.values) do
    if condition.operator == "=" then
      reroll_index[condition.value] = true
    elseif (condition.operator == "<" or condition.operator == "<=") and condition <= 20 then
      local range = condition.operator == "<" and condition.value - 1 or condition.value
      for i = 1, range do
        reroll_index[i] = true
      end
    else
      table.insert(range_conditions, condition)
    end
  end

  local max = math.min(1000, die.modifiers.reroll.limit or 1000)
  local tries = 1

  for _, roll in ipairs(rolls) do
    while shouldReroll(roll, reroll_index, range_conditions) and tries < max do
      local replacement = {
        quantity = 1,
        sides = die.sides,
        type = "die_roll"
      }

      roll.value = roller(replacement, true)
      tries = tries + 1
    end
  end
end
