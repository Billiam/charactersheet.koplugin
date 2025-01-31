local dice = require("charsheet/lib/dice_parser/dice_parser")
local _t = require("charsheet/lib/table_util")
local operations = require("charsheet/lib/dice_parser/operations")
local modifiers = require("charsheet/lib/dice_parser/modifiers")

local DiceRoller = {}
DiceRoller.__index = DiceRoller

--TODO multiple results
-- math:
--  round, min, max, clamp, rnd
--  rounddown, roundup, roundeven, roundodd, roundtozero, roundfromzero
--  check, compare
--  variables

function DiceRoller:new(definition, random)
  local o = {
    definition = definition,
    random_impl = random or math.random,
    rolls = {}
  }
  return setmetatable(o, self)
end

function DiceRoller:fromString(str, random)
  local definition = dice.expression()(str)
  return self:new(definition, random)
end

function DiceRoller:run()
  local new_definition = _t.clone(self.definition, true)
  self.rolls = {}

  return self:getValue(new_definition), new_definition
end

function DiceRoller:processModifiers(die, rolls)
  if not die.modifiers then
    return
  end

  local sorted_rolls = _t.clone(rolls)
  table.sort(sorted_rolls, function(a, b)
    return a.value > b.value
  end)

  -- TODO unique before or after explosion
  -- TODO reroll before or after explosion
  local modifier_order = { "clamp", "value_replacement", "reroll", "explode", "unique", "keep", "drop", "count" }
  for _, type in ipairs(modifier_order) do
    if die.modifiers[type] then
      local new_rolls = modifiers[type](die, sorted_rolls, self:reroller(die.modifiers))

      if new_rolls then
        for _, roll in ipairs(new_rolls) do
          table.insert(rolls, roll)
        end
      end
    end
  end
end

function DiceRoller:reroller(previous_modifiers)
  -- TODO issue also need to be able to process full new expression rolls
  -- TODO which modifiers should affect explosion, rerolling
  -- should reroll/unique trigger after explode?
  local retainable_modifiers = { "clamp", "value_replacement" }

  return function(definition, retain_modifiers)
    if retain_modifiers and definition.type == "die_roll" then
      for _, name in ipairs(retainable_modifiers) do
        if previous_modifiers[name] then
          definition.modifiers = definition.modifiers or {}
          definition.modifiers[name] = previous_modifiers[name]
        end
      end
    end

    return DiceRoller:new(definition, self.random_impl):run()
  end
end

function DiceRoller:roll(die)
  local result = 0
  local rolls = {}
  for i = 1, die.quantity do
    local value = self.random_impl(1, die.sides)

    rolls[i] = { value = value, sides = die.sides }
  end

  self:processModifiers(die, rolls)
  local roll_sum = die.count_result or _t.reduce(rolls, 0, function(res, roll)
    if not roll.drop then
      return res + roll.value
    end
    return res
  end)

  die.rolls = rolls
  die.roll_result = roll_sum
  return result + roll_sum
end

function DiceRoller:range(node)
  return self.random_impl(node.from, node.to)
end

function DiceRoller:getValue(node)
  if not node then
    error()
  end

  if node.type == "addition" or node.type == "multiplication" then
    local result = 0
    for _, child in ipairs(node.values) do
      local mult = child.value.negate and -1 or 1
      result = operations.math[child.operator](result, self:getValue(child.value) * mult)
    end
    return result
  elseif node.type == "integer" then
    return node.value
  elseif node.type == "die_roll" then
    local result = self:roll(node)
    for _, roll in ipairs(node.rolls) do
      table.insert(self.rolls, roll)
    end
    return result
  elseif node.type == "range" then
    return self:range(node)
  end
end

return DiceRoller
