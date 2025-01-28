local operations = require("charsheet/lib/dice_parser/operations")

local dropByIndex = function(rolls, min, max)
  if not min or not max then
    return
  end
  min = math.max(1, min)
  max = math.min(#rolls, max)

  for i, roll in ipairs(rolls) do
    if i >= min and i <= max then
      roll.drop = true
    end
  end
end

return function(die, rolls, _)
  if not die.modifiers.drop then
    return
  end
  if die.modifiers.drop.high then
    dropByIndex(rolls, 1, die.modifiers.drop.high)
  end
  --
  if die.modifiers.drop.low then
    dropByIndex(rolls, #rolls - die.modifiers.drop.low + 1, #rolls)
  end

  if die.modifiers.drop.values then
    --TODO: sort modifiers by effective range, and/or create index
    for i, roll in ipairs(rolls) do
      for _, drop_condition in ipairs(die.modifiers.drop.values) do
        if operations.equality[drop_condition.operator](roll.value, drop_condition.value) then
          roll.drop = true
          break
        end
      end
    end
  end
end
