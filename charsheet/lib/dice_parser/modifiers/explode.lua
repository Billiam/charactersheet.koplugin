local _t = require("charsheet/lib/table_util")
local operations = require("charsheet/lib/dice_parser/operations")

local insertDieSorted = function(rolls, new_roll)
  if #rolls == 0 then
    rolls[1] = new_roll
    return
  end

  local inserted = false

  for i, roll in ipairs(rolls) do
    if new_roll.value > roll.value then
      table.insert(rolls, i, new_roll)
      inserted = true
      break
    end
  end

  if not inserted then
    table.insert(rolls, new_roll)
  end
end

-- TODO clamp needs to apply to new rolls
-- dropped dice still explode
local explodeReduced = function(die, rolls, reroll)
  local new_rolls = {}
  local explodable_dice = _t.select(rolls, function(roll)
    return roll.value > 1
  end)

  while #explodable_dice > 0 do
    local new_explosions = {}
    for _, roll in ipairs(explodable_dice) do
      roll.exploded = true
      local roll_config = {
        type = "die_roll",
        quantity = {
          type = "integer",
          value = 1
        },
        sides = {
          type = "integer",
          value = roll.value
        }
      }

      local _, new_roll_config = reroll(roll_config, true)
      local new_roll = new_roll_config.rolls[1]

      insertDieSorted(rolls, new_roll)
      table.insert(new_rolls, new_roll)
      if new_roll.value > 1 then
        table.insert(new_explosions, new_roll)
      end
    end

    explodable_dice = new_explosions
  end

  return new_rolls
end

local patternMatches = function(rolls, condition)
  local match_index = {}
  for _, pattern_item in ipairs(condition.values) do
    local found_match = false
    for i, roll in ipairs(rolls) do
      if not match_index[i] and operations.equality[pattern_item.operator](roll.value, pattern_item.value.value) then
        match_index[i] = true
        found_match = true
        break
      end
    end

    if not found_match then
      return
    end
  end

  local results = {}
  for i, _ in pairs(match_index) do
    table.insert(results, rolls[i])
  end
  return { results }
end

local inequalityMatches = function(rolls, condition)
  return _t.select(rolls, function(roll)
    return not roll.exploded and operations.equality[condition.operator](roll.value, condition.value.value)
  end)
end

local rollMatches = function(rolls, condition)
end

local sortConditions = function(conditions)
  local sorted_conditions = _t.clone(conditions)
  table.sort(sorted_conditions, function(a, b)
    if a.operator == b.operator then
      if a.operator == "<" or a.operator == "<=" then
        return a < b
      else
        return a > b
      end
    else
      if a.operator == "=" then
        return true
      end
      if b.operator == "=" then
        return false
      end
      if a.operator == "<" or a.operator == "<=" then
        return true
      end
      return false
    end
  end)
  return sorted_conditions
end

local function markExploded(dice)
  local count = 0
  for _, set in ipairs(dice) do
    if set.value then
      count = count + 1
      set.exploded = true
    else
      markExploded(set)
      count = count + 1
    end
  end

  return count
end

return function(die, rolls, reroll)
  if not die.modifiers.explode then
    return
  end
  local new_rolls = {}

  local explosion = die.modifiers.explode
  if explosion.type == "explode_reduced" then
    return explodeReduced(die, rolls, reroll)
  end

  local conditions = explosion.values
  if not conditions then
    conditions = { { value = die.sides, operator = "=" } }
  end

  local sorted_conditions = sortConditions(conditions)
  local remaining_rolls = explosion.type == "explode_many" and 1000 or 1

  while remaining_rolls > 0 do
    remaining_rolls = remaining_rolls - 1

    local new_explosions = {}
    for _, condition in ipairs(sorted_conditions) do
      local exploded_dice
      if condition.type == "pattern" then
        exploded_dice = patternMatches(rolls, condition)
      else
        exploded_dice = inequalityMatches(rolls, condition)
      end

      if exploded_dice and #exploded_dice > 0 then
        local roll_config

        if condition.explodes_with then
          roll_config = _t.clone(condition.explodes_with, true)
        else
          roll_config = {
            type = "die_roll",
            sides = die.sides,
            quantity = explosion.quantity,
            share_dice_pool = true
          }
        end

        local count = markExploded(exploded_dice)
        for _ = 1, count do
          table.insert(new_explosions, roll_config)
        end
      end
    end

    if #new_explosions > 0 then
      for _, config in ipairs(new_explosions) do
        local _, new_definition = reroll(config, config.share_dice_pool)
        for _, roll in ipairs(new_definition.rolls) do
          if config.share_dice_pool then
            insertDieSorted(rolls, roll)
          end
          table.insert(new_rolls, roll)
        end
      end
    else
      break
    end
  end

  return new_rolls
end
