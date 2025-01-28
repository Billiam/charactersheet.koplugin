return function(die, rolls, _)
  if not die.modifiers.clamp then
    return
  end

  local max = die.modifiers.clamp.max or die.sides
  local min = die.modifiers.clamp.min or 1
  for _, roll in ipairs(rolls) do
    roll.value = math.max(math.min(max, roll.value), min)
  end
end
