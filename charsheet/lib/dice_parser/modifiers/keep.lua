local keepByIndex = function(rolls, min, max)
  if not min or not max then
    return
  end
  min = math.max(1, min)
  max = math.min(#rolls, max)

  for i, roll in ipairs(rolls) do
    if not (i >= min and i <= max) then
      roll.drop = true
    end
  end
end

return function(die, rolls)
  if not die.modifiers.keep then
    return
  end
  local min_index, max_index
  -- sort by value
  if die.modifiers.keep.high then
    min_index = 1
    max_index = die.modifiers.keep.high
  elseif die.modifiers.keep.low then
    min_index = #rolls - die.modifiers.keep.low + 1
    max_index = #rolls
  elseif die.modifiers.keep.middle then
    local middle = (#rolls + 1) / 2
    min_index = math.ceil(middle - die.modifiers.keep.middle / 2 + 0.25)
    max_index = math.floor(middle + die.modifiers.keep.middle / 2)
  end

  keepByIndex(rolls, min_index, max_index)
end
