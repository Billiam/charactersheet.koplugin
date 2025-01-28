local operations = require("charsheet/lib/dice_parser/operations")

local skipRoll = function(roll, skip_index, range_conditions)
  if skip_index[roll.value] then
    return true
  end

  for _, condition in ipairs(range_conditions) do
    if operations.equality[condition.operator](roll.value, condition.value) then
      return true
    end
  end

  return false
end

return function(die, rolls, reroll)
  if not die.modifiers.unique and #rolls > 1 then
    return
  end

  local index = {}
  local skip_index = {}
  local range_conditions = {}

  for _, condition in ipairs(die.modifiers.unique.values) do
    if condition.operator == "=" then
      skip_index[condition.value] = true
    elseif (condition.operator == "<" or condition.operator == "<=") and condition <= 20 then
      local range = condition.operator == "<" and condition.value - 1 or condition.value
      for i = 1, range do
        skip_index[i] = true
      end
    else
      table.insert(range_conditions, condition)
    end
  end

  local tries = 1

  for i, roll in ipairs(rolls) do
    if index[roll.value] then
      while index[roll.value] and not skipRoll(roll, skip_index, range_conditions) and tries < 1000 do
        -- TODO: should rerolls consider modifiers?
        local replacement = {
          quantity = 1,
          sides = die.sides,
          type = "die_roll"
        }
        -- any modifiers that come before this one have not applied. Maybe unique is early, after clamp
        roll.value = reroll(replacement, true)
        tries = tries + 1
      end
    end
    index[roll.value] = true
  end
end
