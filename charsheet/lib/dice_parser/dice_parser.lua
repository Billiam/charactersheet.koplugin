local c = require("charsheet/lib/dice_parser/combinators")
local _t = require("charsheet/lib/table_util")
local Parsers = require("charsheet/lib/dice_parser/parser")
local P = Parsers.P
local lazyParser = Parsers.lazy

local numberStr = function()
  return c.concatenate(c.sequence(c.match("^%d+"), c.optional(c.match("^%.%d+"))))
end

local digitStr = function()
  return c.match("^%d+")
end

local toNumber = function()
  return function(result)
    local r = _t.clone(result)
    r.value = tonumber(r.value)
    r.type = "number"
    return r
  end
end

local lazyBracketDieRoll
local lazyBracketExpression
local lazyParenExpression
local lazyMultipleExpressions

local buildMethod = function(name)
  return function()
    return c.map(c.sequence(c.literal(name), c.between("(", ")", lazyMultipleExpressions())), function(result)
      return {
        rest = result.rest,
        type = "method",
        method = result.values[1].value,
        values = result.values[2].values
      }
    end)
  end
end

local floor = buildMethod('floor')
local ceil = buildMethod('ceil')
local round = buildMethod('round')
local abs = buildMethod('abs')

local sin = buildMethod('sin')
local cos = buildMethod('cos')
local tan = buildMethod('tan')
local asin = buildMethod('asin')
local acos = buildMethod('acos')
local atan = buildMethod('atan')
local sqrt = buildMethod('sqrt')
local sign = buildMethod('sign')

local method = function()
  return c.any(
    floor(),
    ceil(),
    round(),
    abs(),

    sin(),
    cos(),
    tan(),
    asin(),
    acos(),
    atan(),
    sqrt(),
    sign()
  )
end

local integer = P("integer", function()
  return c.map(digitStr(), toNumber())
end)

local number = P("number", function()
  return c.map(numberStr(), toNumber())
end)

local variableChars = P("", function()
  return c.match("^[%w_-]+")
end)

local variables = P("variable", function()
  return c.map(
    c.list(".", variableChars()),
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
end)

local interpolation = function()
  return c.between(c.literal("{{"), c.literal("}}"), variables())
end

local fixedValue = P("fixed_value", function()
  return c.any(number(), interpolation(), method())
end)

local fixedInteger = P("fixed_integer", function()
  return c.any(integer(), interpolation(), method())
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
    fixedValue()
  ), function(result)
    local r = _t.clone(result)
    r.inequality = result.values[1].value
    r.value = result.values[2]
    r.values = nil
    return r
  end)
end)

local defaultInteger = function(default)
  return c.map(
    c.optional(fixedInteger()),
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

local die = P("die", function()
  return c.map(c.sequence(
    defaultInteger(1),
    c.literal("d"),
    fixedInteger()
  ), function(result)
    return {
      rest = result.rest,
      quantity = result.values[1],
      sides = result.values[3],
    }
  end)
end)

local keepHighest = P("keep_highest", function()
  return c.map(c.nthValue(2, c.sequence(c.literal("K"), defaultInteger(1))),
    function(result)
      return {
        type = "keep",
        high = result,
        rest = result.rest
      }
    end
  )
end)

local keepLowest = P("keep_lowest", function()
  return c.map(c.nthValue(2, c.sequence(c.literal("KL"), defaultInteger(1))),
    function(result)
      return {
        type = "keep",
        low = result,
        rest = result.rest
      }
    end
  )
end)

local keepMiddle = P("keep_middle", function()
  return c.map(c.nthValue(2, c.sequence(c.literal("KM"), defaultInteger(1))),
    function(result)
      return {
        type = "keep",
        middle = result,
        rest = result.rest
      }
    end
  )
end)

local keep = P("keep", function()
  return c.any(keepLowest(), keepMiddle(), keepHighest())
end)

local dropHighest = P("drop_highest", function()
  return c.map(c.nthValue(2, c.sequence(c.literal("H"), defaultInteger(1))), function(result)
    return {
      type = "drop",
      high = result,
      rest = result.rest
    }
  end)
end)

local dropLowest = P("drop_lowest", function()
  return c.map(c.nthValue(2, c.sequence(c.literal("L"), defaultInteger(1))), function(result)
    return {
      type = "drop",
      low = result,
      rest = result.rest
    }
  end)
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
    c.dropLeftValue(1, c.sequence(c.literal("D"), c.between("{", "}", dropRolls()))),
    function(result)
      local r = _t.clone(result)
      return {
        type = "drop",
        rest = result.rest,
        values = result.values[1].values
      }
    end)
end)

local drop = P("drop", function()
  return c.any(dropHighest(), dropLowest(), dropCondition())
end)

local clamp = P("clamp", function()
  return c.map(c.dropLeftValue(1, c.sequence(c.ignore("C"), numberInequality(), c.optional(numberInequality()))),
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
  )
end)

local range = P("range", function()
  return c.map(c.sequence(
    fixedValue(), "..", fixedValue()
  ), function(result)
    -- TODO clone in map
    local r = _t.clone(result)
    r.from = result.values[1]
    r.to = result.values[3]
    r.values = nil

    return r
  end)
end)

local replacementValue = P("replacement_value", function()
  return c.any(range(), fixedValue(), lazyBracketDieRoll())
end)

-- TODO allow string value replacements
local valueReplacement = P("value_replacement", function()
  return c.map(c.nthValue(2, c.sequence(
    "V",
    c.between("{", "}",
      c.list(
        ",",
        c.sequence(
          c.optional(c.any("<", ">")),
          fixedValue(),
          "=",
          replacementValue()
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
  end)
end)

local unique = P("unique", function()
  return c.map(c.sequence(c.literal("U"),
    c.optional(c.between("{", "}",
      c.list(",", numberInequality())
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
  end)
end)

local explodeRerollPattern = P("explode_reroll_pattern", function()
  return c.map(c.between("(", ")",
    c.list(",", numberInequality())
  ), function(result)
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
  end)
end)

local isExpression = P("is_expression", function()
  return c.map(c.sequence(
    "=",
    lazyBracketExpression()
  ), function(result)
    return result.values[2]
  end)
end)

local explodeConditions = P("explode_conditions", function()
  return c.between("{", "}",
    c.list(",",
      c.map(
        c.sequence(
          c.any(
            explodeRerollPattern(),
            numberInequality()
          ),
          c.optional(
            isExpression()
          )
        ), function(result)
          if result.values[2].value == nil and result.values[2].parser == nil then
            result.values[2] = nil
          end
          return result
        end)
    )
  )
end)

local buildExplosionParser = function(name, prefix)
  return P(name, function()
    return c.dropLeftValue(1, c.sequence(
      prefix,
      c.optional(explodeConditions()),
      c.optional(fixedInteger()),
      c.optional(".")
    ))
  end)
end

local explodeMany = buildExplosionParser("explode_many", "!")
local explodeOnce = buildExplosionParser("explode_once", "!!")

local explodeReduced = P("explode_reduced", function()
  return c.literal("!!!")
end)

local explode = P("explode", function()
  return c.map(c.any(explodeReduced(), explodeOnce(), explodeMany()), function(result)
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
  end)
end)

local reroll = P("reroll", function()
  return c.map(c.dropLeftValue(1,
    c.sequence(
      "R",
      c.between("{", "}",
        c.list(",", numberInequality())
      ),
      c.optional(numberInequality())
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
  end)
end)

local count = P("count", function()
  return c.map(c.dropLeftValue(1,
    c.sequence(
      "#",
      c.optional(c.between("{", "}",
        c.list(",", numberInequality())
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
  end)
end)

local dieModifier = P("modifiers", function()
  return c.map(c.nOrMoreUnique(0,
    clamp(),
    count(),

    keepLowest(),
    keepMiddle(),
    keepHighest(),

    dropLowest(),
    dropHighest(),
    dropCondition(),

    explode(),
    reroll(),
    unique(),
    valueReplacement()
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
  end)
end)

local dieRoll = P("die_roll", function()
  return c.map(c.sequence(die(), c.optional(dieModifier())), function(result)
    local r = _t.clone(result.values[1])
    r.modifiers = result.values[2]
    r.rest = result.rest
    return r
  end)
end)
local bracketDieRoll = function()
  return c.between("[", "]", dieRoll())
end
lazyBracketDieRoll = function()
  return lazyParser(bracketDieRoll)
end

local value = P("value", function()
  return c.any(dieRoll(), fixedValue())
end)

local negatedValue = P("negated_value", function()
  return c.map(c.sequence("-", value()), function(result)
    local r = _t.clone(result.values[2])
    r.rest = result.rest
    r.negate = true
    return r
  end)
end)
local signedValue = P("signed_value", function()
  return c.any(negatedValue(), value())
end)
local multiplicationOperator = P("multiplication_operator", function()
  return c.any("*", "/")
end)
local exponentiationOperator = P("exponentiation_operator", function()
  return c.literal("^")
end)

local additionOperator = P("addition_operator", function()
  return c.any("+", "-")
end)

local factor = function()
  return c.any(signedValue(), lazyParenExpression())
end

local appendMath = function(operator, type)
  return c.map(c.sequence(operator(), type()), function(result)
    return {
      rest = result.rest,
      operator = result.values[1].value,
      value = result.values[2]
    }
  end)
end

local buildArithmetic = function(name, type, operator)
  return P(name, function()
    return c.map(c.sequence(type(), c.nOrMore(1, appendMath(operator, type))), function(result)
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
  end)
end


--min/max
--check/compare (?)
--clamp (val, min, max)
--sin,cos,tan,asin,acos,atan,atan2(,),tanh,exp(,),sqrt,ln, abs, pow(,), lerp(,,), mod(,), sign


local exponentiation = buildArithmetic("exponentiation", factor, exponentiationOperator)
local coefficient = function()
  return c.any(exponentiation(), factor())
end

local multiplication = buildArithmetic("multiplication", coefficient, multiplicationOperator)
local term = function()
  return c.any(multiplication(), coefficient())
end

local addition = buildArithmetic("addition", term, additionOperator)
local expression = function()
  return c.any(addition(), term())
end

local bracketExpression = function()
  return c.between("[", "]", expression())
end
lazyBracketExpression = function()
  return lazyParser(bracketExpression)
end
local parenExpression = function()
  return c.between("(", ")", expression())
end
lazyParenExpression = function()
  return lazyParser(parenExpression)
end
local multipleExpressions = P("multiple_expressions", function()
  return c.list(",", expression())
end)
lazyMultipleExpressions = function()
  return lazyParser(multipleExpressions)
end

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
