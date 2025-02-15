local c = require("charsheet/lib/dice_parser/combinators")
local _t = require("charsheet/lib/table_util")

local toNumber = function(result)
  local r = _t.clone(result)
  r.value = tonumber(r.value)
  r.type = "number"
  return r
end

local appendMath = function(operator, type)
  return c.map(c.sequence(operator, type), function(result)
    return {
      rest = result.rest,
      operator = result.values[1].value,
      value = result.values[2]
    }
  end)
end

local buildArithmetic = function(name, type, operator)
  return c.label(name, c.map(
    c.sequence(type, c.nOrMore(1, appendMath(operator, type))), function(result)
      local r = {
        type = result.parser,
        rest = result.rest,
        values = {
          {
            operator = "+",
            value = result.values[1]
          },
        }
      }
      for i, v in ipairs(result.values[2].values) do
        r.values[i + 1] = v
      end
      return r
    end)
  )
end

local numberStr = c.concatenate(c.sequence(c.match("^%d+"), c.optional(c.match("^%.%d+"))))

local digitStr = c.match("^%d+")

local expressionDefinition
local expression = function(str)
  return expressionDefinition(str)
end

local dieRollDefinition
local dieRoll = function(str) return dieRollDefinition(str) end

local multipleExpressions = c.label("multiple_expressions", c.list(",", expression))

local buildMethod = function(...)
  local names = { ... }
  local method_name = #names > 1 and c.any(...) or c.literal(names[1])

  return c.map(c.sequence(method_name, c.between("(", ")", multipleExpressions)),
    function(result)
      return {
        rest = result.rest,
        type = "method",
        method = names[1],
        values = result.values[2].values
      }
    end)
end

local abs = buildMethod("abs")
local acos = buildMethod("acos")
local asin = buildMethod("asin")
local atan = buildMethod("atan2", "atan")
local ceil = buildMethod("ceil", "roundup", "rup")
local clampMethod = buildMethod("clamp")
local cos = buildMethod("cos")
local floor = buildMethod("floor", "rounddown", "rdown")
local lerp = buildMethod("lerp")
local mod = buildMethod("mod")
local pow = buildMethod("pow")
local rnd = buildMethod("rnd")
local round = buildMethod("round")
local roundEven = buildMethod("roundeven", "reven", "roundtoeven")
local roundFromZero = buildMethod("roundfromzero")
local roundOdd = buildMethod("roundodd", "rodd", "roundtoodd")
local roundToZero = buildMethod("roundtozero", "truncate", "trunc")
local sign = buildMethod("sign")
local sin = buildMethod("sin")
local sqrt = buildMethod("sqrt")
local tan = buildMethod("tan")

local method = c.any(
  abs,
  acos,
  asin,
  atan,
  ceil,
  clampMethod,
  cos,
  floor,
  lerp,
  mod,
  pow,
  rnd,
  roundEven,
  roundFromZero,
  roundOdd,
  roundToZero,

  round,

  sign,
  sin,
  sqrt,
  tan
)

local integer = c.label("integer", c.map(digitStr, toNumber))
local number = c.label("number", c.map(numberStr, toNumber))

local variableChars = c.match("^[%w_-]+")

local variables = c.label("variable",
  c.map(
    c.list(".", variableChars),
    function(result)
      local r = {
        rest = result.rest,
        values = {}
      }
      for i, key in ipairs(result.values) do
        r.values[i] = key.value
      end
      return r
    end
  )
)

local interpolation = c.between(c.literal("{{"), c.literal("}}"), variables)

local fixedValue = c.label("fixed_value", c.any(number, interpolation, method))

local fixedInteger = c.label("fixed_integer", c.any(integer, interpolation, method))

local inequality = c.label("inequality", c.concatenate(
  c.sequence(
    c.any(">", "<"),
    c.optional("=")
  )
))

local numberInequality = c.label("number_inequality", c.map(c.sequence(
  c.optional(inequality),
  fixedValue
), function(result)
  local r = _t.clone(result)
  r.inequality = result.values[1].value
  r.value = result.values[2]
  r.values = nil
  return r
end))

local defaultInteger = function(default)
  return c.map(
    c.optional(fixedInteger),
    function(result)
      if not result.value and not result.values then
        return {
          type = "number",
          value = default,
          rest = result.rest
        }
      end
      return result
    end
  )
end

local bracketExpression = c.between("[", "]", expression)
local parenExpression = c.between("(", ")", expression)

local equalsExpression = c.label("is_expression", c.map(c.sequence(
  "=",
  bracketExpression
), function(result)
  return result.values[2]
end))

local die = c.label("die", c.map(c.sequence(
  defaultInteger(1),
  c.literal("d"),
  fixedInteger
), function(result)
  return {
    rest = result.rest,
    quantity = result.values[1],
    sides = result.values[3],
  }
end))

local keepHighest = c.label("keep_highest", c.map(
  c.nthValue(2, c.sequence(c.literal("K"), defaultInteger(1))),
  function(result)
    return {
      type = "keep",
      high = result,
      rest = result.rest
    }
  end
))

local keepLowest = c.label("keep_lowest", c.map(
  c.nthValue(2, c.sequence(c.literal("KL"), defaultInteger(1))),
  function(result)
    return {
      type = "keep",
      low = result,
      rest = result.rest
    }
  end
))

local keepMiddle = c.label("keep_middle", c.map(
  c.nthValue(2, c.sequence(c.literal("KM"), defaultInteger(1))),
  function(result)
    return {
      type = "keep",
      middle = result,
      rest = result.rest
    }
  end
))

local keep = c.label("keep", c.any(keepLowest, keepMiddle, keepHighest))

local dropHighest = c.label("drop_highest", c.map(
  c.nthValue(2, c.sequence(c.literal("H"), defaultInteger(1))), function(result)
    return {
      type = "drop",
      high = result,
      rest = result.rest
    }
  end
))

local dropLowest = c.label("drop_lowest", c.map(
  c.nthValue(2, c.sequence(c.literal("L"), defaultInteger(1))), function(result)
    return {
      type = "drop",
      low = result,
      rest = result.rest
    }
  end
))

local dropRolls = c.label("drop_rolls", c.map(
  c.list(",", numberInequality), function(result)
    local r = _t.clone(result)
    r.values = _t.map(result.values, function(option)
      return {
        operator = option.inequality or "=",
        value = option.value
      }
    end)
    return r
  end
))

local dropCondition = c.label("drop_condition", c.map(
  c.dropLeftValue(1, c.sequence(c.literal("D"), c.between("{", "}", dropRolls))),
  function(result)
    return {
      type = "drop",
      rest = result.rest,
      values = result.values[1].values
    }
  end
))

local drop = c.label("drop", c.any(dropHighest, dropLowest, dropCondition))

local clamp = c.label("clamp", c.map(
  c.dropLeftValue(1, c.sequence(c.ignore("C"), numberInequality, c.optional(numberInequality))),
  function(result)
    local r = {
      rest = result.rest
    }
    for _, condition in ipairs(result.values) do
      if condition.value then
        if condition.inequality:sub(1, 1) == ">" then
          r.max = condition.value
        else
          r.min = condition.value
        end
      end
    end

    return r
  end
))

local range = c.label("range", c.map(
  c.sequence(
    fixedValue, "..", fixedValue
  ),
  function(result)
    -- TODO clone in map
    local r = _t.clone(result)
    r.from = result.values[1]
    r.to = result.values[3]
    r.values = nil

    return r
  end
))

local explodeRerollPattern = c.label("explode_reroll_pattern", c.map(
  c.between("(", ")",
    c.list(",", numberInequality)
  ),
  function(result)
    return {
      rest = result.rest,
      type = "pattern",
      values = _t.map(result.values, function(item)
        return {
          value = item.value,
          operator = item.inequality or "="
        }
      end)
    }
  end
))

local explodeConditions = c.label("explode_conditions", c.between("{", "}",
  c.list(",",
    c.map(
      c.sequence(
        c.any(
          explodeRerollPattern,
          numberInequality
        ),
        c.optional(
          equalsExpression
        )
      ), function(result)
        if result.values[2].value == nil and result.values[2].parser == nil then
          result.values[2] = nil
        end
        return result
      end)
  )
))

local buildExplosionParser = function(name, prefix)
  return c.label(name,
    c.dropLeftValue(1,
      c.sequence(
        prefix,
        c.optional(explodeConditions),
        c.optional(fixedInteger),
        c.optional(".")
      )
    )
  )
end

local explodeMany = buildExplosionParser("explode_many", "!")
local explodeOnce = buildExplosionParser("explode_once", "!!")

local explodeReduced = c.label("explode_reduced", c.literal("!!!"))

local explode = c.label("explode", c.map(
  c.any(explodeReduced, explodeOnce, explodeMany),
  function(result)
    local r = {
      type = result.type,
      rest = result.rest
    }
    if result.values then
      local conditions = result.values[1]
      r.values = {}

      if conditions.values then
        for i, cond in ipairs(conditions.values) do
          local condition_definition = cond.values[1]
          local condition_result = cond.values[2]
          if condition_definition.type == "pattern" then
            r.values[i] = _t.clone(condition_definition)
          else
            r.values[i] = {
              value = condition_definition.value,
              operator = condition_definition.inequality or "="
            }
          end
          r.values[i].explodes_with = condition_result

          r.values[i].rest = nil
        end
      end

      r.quantity = result.values[2].type and result.values[2] or {
        type = "number",
        value = 1
      }

      if #r.values == 0 then
        r.values = nil
      end
    end

    return r
  end
))

local reroll = c.label("reroll", c.map(
  c.dropLeftValue(1,
    c.sequence(
      "R",
      c.between("{", "}",
        c.list(",", numberInequality)
      ),
      c.optional(numberInequality)
    )
  ), function(result)
    local r = {
      rest = result.rest,
      values = {},
      limit = result.values[2].value
    }

    for i, condition in ipairs(result.values[1].values) do
      r.values[i] = {
        operator = condition.inequality or "=",
        value = condition.value
      }
    end

    return r
  end
))

local count = c.label("count", c.map(
  c.dropLeftValue(1,
    c.sequence(
      "#",
      c.optional(c.between("{", "}",
        c.list(",", numberInequality)
      ))
    )
  ), function(result)
    local r = {
      rest = result.rest,
      values = {},
    }

    if result.values[1].values then
      for i, condition in ipairs(result.values[1].values) do
        r.values[i] = {
          operator = condition.inequality or "=",
          value = condition.value
        }
      end
    end

    return r
  end
))

local bracketDieRoll = c.between("[", "]", dieRoll)

local replacementValue = c.label("replacement_value", c.any(range, fixedValue, bracketDieRoll))

-- TODO allow string value replacements
local valueReplacement = c.label("value_replacement", c.map(
  c.nthValue(2, c.sequence(
    "V",
    c.between("{", "}",
      c.list(
        ",",
        c.sequence(
          c.optional(c.any("<", ">")),
          fixedValue,
          "=",
          replacementValue
        )
      )
    )
  )), function(result)
    local r = {
      rest = result.rest
    }
    r.values = _t.map(result.values, function(replacement)
      local parsed_replacement = replacement.values[4]
      local value = {
        value = replacement.values[2],
        operator = replacement.values[1].value or "=",
      }

      if parsed_replacement.type == "range" then
        value.replacement = {
          from = parsed_replacement.from,
          to = parsed_replacement.to,
        }
        value.type = "range"
      elseif parsed_replacement.type == "die_roll" then
        value.replacement = _t.clone(parsed_replacement)
        value.type = "die_roll"
      else
        value.replacement = parsed_replacement
        value.type = "value"
      end

      return value
    end)

    return r
  end
))

local unique = c.label("unique", c.map(
  c.sequence(c.literal("U"),
    c.optional(c.between("{", "}",
      c.list(",", numberInequality)
    ))), function(result)
    local r = {
      rest = result.rest,
      values = {}
    }
    if result.values[2].values then
      for i, v in ipairs(result.values[2].values) do
        r.values[i] = { value = v.value, operator = v.inequality or "=" }
      end
    end
    return r
  end
))

local dieModifier = c.label("modifiers", c.map(
  c.nOrMoreUnique(0,
    clamp,
    count,

    keepLowest,
    keepMiddle,
    keepHighest,

    dropLowest,
    dropHighest,
    dropCondition,

    explode,
    reroll,
    unique,
    valueReplacement
  ), function(result)
    local r = {
      rest = result.rest,
    }
    local merge_keys = { "drop", "keep", "explode", "clamp", "unique", "count", "reroll", "value_replacement" }
    for _, modifier in ipairs(result.values) do
      for _, key in ipairs(merge_keys) do
        if modifier.type == key or modifier.parser == key then
          r[key] = _t.merge(r[key] or {}, modifier)
        end
      end
    end

    return r
  end
))

dieRollDefinition = c.label("die_roll", c.map(
  c.sequence(die, c.optional(dieModifier)),
  function(result)
    local r = _t.clone(result.values[1])
    r.modifiers = result.values[2]
    r.rest = result.rest
    return r
  end
))

local value = c.label("value", c.any(dieRoll, fixedValue))

local negatedValue = c.label("negated_value", c.map(
  c.sequence("-", value),
  function(result)
    local r = _t.clone(result.values[2])
    r.rest = result.rest
    r.negate = true
    return r
  end
))

local signedValue = c.label("signed_value", c.any(negatedValue, value))

local multiplicationOperator = c.label("multiplication_operator", c.any("*", "/"))

local exponentiationOperator = c.label("exponentiation_operator", c.literal("^"))

local additionOperator = c.label("addition_operator", c.any("+", "-"))

local factor = c.any(signedValue, parenExpression)

local exponentiation = buildArithmetic("exponentiation", factor, exponentiationOperator)

local coefficient = c.any(exponentiation, factor)

local multiplication = buildArithmetic("multiplication", coefficient, multiplicationOperator)
local term = c.any(multiplication, coefficient)

local addition = buildArithmetic("addition", term, additionOperator)

expressionDefinition = c.any(addition, term)

return {
  clamp = clamp,
  count = count,
  die = die,
  dieModifier = dieModifier,
  dieRoll = dieRoll,

  drop = drop,
  dropHighest = dropHighest,
  dropLowest = dropLowest,
  dropCondition = dropCondition,

  keep = keep,
  keepHighest = keepHighest,
  keepMiddle = keepMiddle,
  keepLowest = keepLowest,

  explode = explode,
  reroll = reroll,
  unique = unique,
  valueReplacement = valueReplacement,
  method = method,

  expression = expression,
  multipleExpressions = multipleExpressions,
}
