local c = require("charsheet/lib/dice_parser/base_combinator")
local _t = require("charsheet/lib/table_util")
local dump = require("charsheet/lib/dump")
local P = require("charsheet/lib/dice_parser/parser")

local digits = function()
  return c.match("^%d+")
end

local toInt = function()
  return function(result)
    local r = _t.clone(result)
    r.value = math.floor(tonumber(r.value))
    return r
  end
end

local digitsAsInt = P("integer", function()
  return c.map(digits(), toInt())
end)


local operator = P("operator", function()
  return c.any("+", "-", "*", "/")
end)

local inequality = P("inequality", function()
  return c.concatenate(
    c.sequence(
      c.any(">", "<"),
      c.optional("=")
    )
  )
end)

local numberInequality = P("number_inequality", function()
  return c.map(c.sequence(
    c.optional(inequality()),
    digitsAsInt()
  ), function(result)
    local r = _t.clone(result)
    r.inequality = result.values[1].value
    r.value = result.values[2].value
    r.values = nil
    return r
  end)
end)

local die = P("die", function()
  return c.sequence(
    c.capture("quantity", digitsAsInt()),
    c.literal("d"),
    c.capture("sides", digitsAsInt())
  )
end)

local keepCount = P("keep_count", function()
  return c.capture("keep_count", digitsAsInt())
end)
local keepHighest = P("keep_highest", function()
  return c.sequence(c.literal("K"), c.optional(keepCount()))
end)
local keepLowest = P("keep_lowest", function()
  return c.sequence(c.literal("KL"), c.optional(keepCount()))
end)
local keepMiddle = P("keep_middle", function()
  return c.sequence(c.literal("KM"), c.optional(keepCount()))
end)
local keep = P("keep", function()
  return c.map(c.any(keepLowest(), keepMiddle(), keepHighest()), function(result)
    return {
      rest = result.rest,
      keep = result.parser,
      keep_count = _t.dig(result, "captures", "keep_count")
    }
  end)
end)

local dropCount = P("drop_count", function()
  return c.capture("drop_count", digitsAsInt())
end)
local dropHighest = P("drop_highest", function()
  return c.sequence(c.literal("H"), c.optional(dropCount()))
end)
local dropLowest = P("drop_lowest", function()
  return c.sequence(c.literal("L"), c.optional(dropCount()))
end)

local dropRolls = P("drop_rolls", function()
  return c.map(c.list(",", numberInequality()), function(result)
    local r = _t.clone(result)
    r.values = _t.map(result.values, function(option)
      return {
        operator = option.inequality or "=",
        value = option.value
      }
    end)
    return r
  end)
end)

local dropCondition = P("drop_condition", function()
  return c.map(
    c.sequence(c.literal("D"), c.between("{", "}", dropRolls())),
    function(result)
      local r = _t.clone(result)
      r.values = result.values[2].values

      return r
    end)
end)

local drop = P("drop", function()
  return c.map(c.any(dropHighest(), dropLowest(), dropCondition()), function(result)
    return {
      rest = result.rest,
      drop = result.parser,
      drop_conditions = result.parser == "drop_condition" and result.values or nil,
      drop_count = _t.dig(result, "captures", "drop_count")
    }
  end)
end)

local clamp = P("clamp", function()
  return c.map(c.dropLeftValue(1, c.sequence(c.ignore("C"), numberInequality(), c.optional(numberInequality()))),
    function(result)
      local r = _t.clone(result)
      r.clamp = {}

      for _, condition in ipairs(result.values) do
        if condition.value then
          if condition.inequality:sub(1, 1) == ">" then
            r.clamp.max = condition.value
          else
            r.clamp.min = condition.value
          end
        end
      end

      return r
    end
  )
end)

local variableChars = P("", function()
  return c.match("^[%w_]+")
end)

local variables = P("variables", function()
  return c.list(",", variableChars())
end)

local range = P("range", function()
  return c.map(c.sequence(
    digitsAsInt(), "..", digitsAsInt()
  ), function(result)
    -- TODO clone in map
    local r = _t.clone(result)
    r.from = result.values[1].value
    r.to = result.values[3].value
    r.values = nil

    return r
  end)
end)

local replacementValue = P("replacement_value", function()
  -- when should captures be terminated?
  -- TODO allow full dice roll in replacement value instead of simple xdx roll
  return c.any(range(), digitsAsInt(), c.between("[", "]", die()))
end)

-- TODO allow string value replacements
local valueReplacement = P("value_replacement", function()
  return c.map(c.nthValue(2, c.sequence(
    "V",
    c.between("{", "}",
      c.list(
        ",",
        c.sequence(
          c.capture("condition", c.optional(c.any("<", ">"))),
          c.capture("value", digitsAsInt()),
          "=",
          c.capture("replacement", replacementValue())
        )
      )
    )
  )), function(result)
    local r = _t.clone(result)
    r.replacement = _t.map(result.values, function(replacement)
      local parsed_replacement = replacement.values[4]
      local replacement_value

      if parsed_replacement.parser == "range" then
        replacement_value = {
          from = replacement.values[4].from,
          to = replacement.values[4].to,
          type = "random",
        }
      elseif parsed_replacement.parser == "die" then
        replacement_value = {
          type = "roll",
          sides = replacement.captures.sides,
          quantity = replacement.captures.quantity
        }
      else
        replacement_value = replacement.captures.replacement
      end

      return {
        value = replacement.captures.value,
        replacement = replacement_value,
        condition = replacement.captures.condition or "=",
      }
    end)
    r.captures = nil

    return r
  end)
end)

local unique = P("unique", function()
  return c.map(c.sequence(c.literal("U"),
    c.optional(c.between("{", "}",
      c.list(",", digitsAsInt())
    ))), function(result)
    local r = _t.clone(result)
    r.unique = {}
    if result.values[2].values then
      for i, v in ipairs(result.values[2].values) do
        r.unique[i] = v.value
      end
    end
    r.values = nil
    return r
  end)
end)


local interpolation = function()
  return c.between(c.literal("{{"), c.literal("}}"), variables())
end

local dieModifier = P("modifiers", function()
  return c.nOrMoreUnique(0,
    c.capture("keep", keep()),
    c.capture("drop", drop()),
    c.capture("clamp", clamp()),
    c.unique("unique", unique()),
    c.capture("value_replacement", valueReplacement())
  )
end)

return {
  die = die,
  keep = keep,
  drop = drop,
  clamp = clamp,
  unique = unique,
  valueReplacement = valueReplacement,
  dieModifier,
}
