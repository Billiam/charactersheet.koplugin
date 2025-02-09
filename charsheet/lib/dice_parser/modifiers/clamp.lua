local _t = require("charsheet/lib/table_util")

return function(die, rolls, _)
  if not die.modifiers.clamp then
    return
  end

  local max = _t.dig(die.modifiers.clamp, "max", "value") or die.sides.value
  local min = _t.dig(die.modifiers.clamp, "min", "value") or 1
  for _, roll in ipairs(rolls) do
    roll.value = math.max(math.min(max, roll.value), min)
  end
end
