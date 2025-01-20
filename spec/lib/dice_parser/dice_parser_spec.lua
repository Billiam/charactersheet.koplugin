local parser = require("charsheet/lib/dice_parser/parser")
local dice = require("charsheet/lib/dice_parser/dice_parser")
local _t = require("charsheet/lib/table_util")

describe("dice", function()
  describe("keep", function()
    it("matches keep highest", function()
      local result = dice.keep()("K")

      assert.equal("keep", result.type)
      assert.equal(1, result.high)
    end)

    it("matches keep highest with count", function()
      local result = dice.keep()("K3")

      assert.equal("keep", result.type)
      assert.equal(3, result.high)
    end)

    it("matches keep lowest", function()
      local result = dice.keep()("KL")
      assert.equal("keep", result.type)
      assert.equal(1, result.low)
    end)

    it("matches keep lowest with count", function()
      local result = dice.keep()("KL3")

      assert.equal("keep", result.type)
      assert.equal(3, result.low)
    end)

    it("matches keep middle", function()
      local result = dice.keep()("KM")

      assert.equal("keep", result.type)
      assert.equal(1, result.middle)
    end)

    it("matches keep middle with count", function()
      local result = dice.keep()("KM3")

      assert.equal("keep", result.type)
      assert.equal(3, result.middle)
    end)
  end)

  describe("drop", function()
    it("matches drop highest", function()
      local result = dice.drop()("H")

      assert.equal("drop", result.type)
      assert.equal(1, result.high)
    end)

    it("matches drop highest with count", function()
      local result = dice.drop()("H3")

      assert.equal("drop", result.type)
      assert.equal(3, result.high)
    end)

    it("matches drop lowest", function()
      local result = dice.drop()("L")

      assert.equal("drop", result.type)
      assert.equal(1, result.low)
    end)

    it("matches drop lowest with count", function()
      local result = dice.drop()("L3")

      assert.equal("drop", result.type)
      assert.equal(3, result.low)
    end)

    describe("drop conditionally", function()
      it("returns drop conditions", function()
        local result = dice.drop()("D{<3}")

        assert.equal("drop", result.type)
        assert.are.same({
          { value = 3, operator = "<" }
        }, result.values)
      end)

      it("returns multiple drop conditions", function()
        local result = dice.drop()("D{<2,4,>5,>=6}")

        assert.equal("drop", result.type)
        assert.are.same(
          {
            { value = 2, operator = "<" },
            { value = 4, operator = "=" },
            { value = 5, operator = ">" },
            { value = 6, operator = ">=" }
          },
          result.values)
      end)
    end)
  end)

  describe("clamp", function()
    it("returns minimum clamp conditions", function()
      local result = dice.clamp()("C<2")

      assert.equal("clamp", result.parser)
      assert.equal(2, result.min)
    end)

    it("returns maximum clamp conditions", function()
      local result = dice.clamp()("C>5")

      assert.equal("clamp", result.parser)
      assert.equal(5, result.max)
    end)

    it("returns range clamp conditions", function()
      local result = dice.clamp()("C<2>5")

      assert.equal("clamp", result.parser)
      assert.equal(2, result.min)
      assert.equal(5, result.max)
    end)
  end)

  -- TODO: should modifiers use a table with keys, or an array of types?
  describe("unique", function()
    it("return a unique flag", function()
      local result = dice.unique()("U")

      assert.equal("unique", result.parser)
      assert.are.same({}, result.values)
    end)

    it("returns non-rerolled conditions", function()
      local result = dice.unique()("U{5}")

      assert.equal("unique", result.parser)
      assert.are.same({ { value = 5, operator = "=" } }, result.values)
    end)
  end)

  describe("replacement", function()
    it("returns a direct value map", function()
      local result = dice.valueReplacement()("V{4=6,5=6}")

      assert.equal("value_replacement", result.parser)
      assert.are.same(
        {
          { value = 4, type = "value", replacement = 6, condition = "=" },
          { value = 5, type = "value", replacement = 6, condition = "=" }
        },
        result.values
      )
    end)

    it("returns ranged value map", function()
      local result = dice.valueReplacement()("V{<5=0,>15=20}")

      assert.equal("value_replacement", result.parser)
      assert.are.same(
        {
          { value = 5,  type = "value", replacement = 0,  condition = "<" },
          { value = 15, type = "value", replacement = 20, condition = ">" }
        },
        result.values
      )
    end)

    it("replaces values with random ranges", function()
      local result = dice.valueReplacement()("V{>5=10..20}")

      assert.equal("value_replacement", result.parser)
      assert.are.same(
        {
          {
            value = 5,
            condition = ">",
            type = "range",
            replacement = {
              from = 10,
              to = 20
            }
          }
        },
        result.values
      )
    end)

    it("replaces values with new rolls", function()
      local result = dice.valueReplacement()("V{>5=[2d6]}")

      assert.equal("value_replacement", result.parser)
      assert.are.same(
        {
          {
            value = 5,
            condition = ">",
            type = "roll",
            replacement = {
              quantity = 2,
              sides = 6
            }
          }
        },
        result.values
      )
    end)
  end)

  describe("explode", function()
    it("matches explosion", function()
      local result = dice.explode()("!")

      assert.equal("explode", result.parser)
      assert.equal("explode_many", result.type)
      assert.are.same({}, result.values)
    end)

    it("explodes extra dice", function()
      local result = dice.explode()("!3")

      assert.equal(3, result.quantity)
    end)

    it("explodes on selectable values", function()
      local result = dice.explode()("!{<2,6}")

      assert.are.same({ value = 2, operator = "<" }, result.values[1])
      assert.are.same({ value = 6, operator = "=" }, result.values[2])
    end)

    it("explodes with a new roll", function()
      local result = dice.explode()("!{20=[2d6]}")

      local condition = result.values[1]
      assert.equal("roll", condition.type)
      assert.equal(20, condition.value)
      assert.equal("=", condition.operator)

      assert.equal(6, condition.roll.sides)
      assert.equal(2, condition.roll.quantity)
    end)

    it("matches explode once", function()
      local result = dice.explode()("!!")

      assert.equal("explode", result.parser)
      assert.equal("explode_once", result.type)
      assert.are.same({}, result.values)
    end)

    it("matches reducing explosion", function()
      local result = dice.explode()("!!!")

      assert.equal("explode", result.parser)
      assert.equal("explode_reduced", result.type)
      assert.are.same({}, result.values)
    end)

    it("returns nil on error", function()
      local result = dice.explode()("{3,6}")

      assert.is_nil(result)
    end)
  end)

  describe("reroll", function()
    it("matches reroll conditions", function()
      local result = dice.reroll()("R{2,>5}2")

      assert.equal("reroll", result.parser)
      assert.equal(2, result.limit)
      assert.are.same({
        { value = 2, operator = "=" },
        { value = 5, operator = ">" },
      }, result.values)
    end)
  end)

  describe("count", function()
    it("matches count", function()
      local result = dice.count()("#")

      assert.equal("count", result.parser)
      assert.are.same({}, result.values)
    end)

    it("supports count conditions", function()
      local result = dice.count()("#{<4,5}")

      assert.equal("count", result.parser)
      assert.are.same({
        { value = 4, operator = "<" },
        { value = 5, operator = "=" },
      }, result.values)
    end)
  end)

  describe("diceModifier", function()
    it("matches complex modifiers", function()
      local result = dice.dieModifier()("KL3H3L2D{<4}!{4,20=[2d8]}C<2U{5}#{<2,5}R{2}3V{>5=[2d6]}")

      assert.equal("", result.rest)
      assert.equal("modifiers", result.parser)

      --drop
      assert.equal(3, result.drop.high)
      assert.equal(2, result.drop.low)
      assert.are.same({ { operator = "<", value = 4 } }, result.drop.values)

      --keep
      assert.equal(3, result.keep.low)
      --clamp
      assert.equal(2, result.clamp.min)
      --unique
      assert.are.same({ { value = 5, operator = "=" } }, result.unique.values)
      --count
      assert.are.same({ { value = 2, operator = "<" }, { value = 5, operator = "=" } }, result.count.values)

      -- reroll
      assert.equal(3, result.reroll.limit)
      assert.are.same({ { value = 2, operator = "=" } }, result.reroll.values)

      -- value replacement
      assert.are.same({
          {
            value = 5,
            type = "roll",
            replacement = {
              sides = 6,
              quantity = 2
            },
            condition = ">"
          }
        },
        result.value_replacement.values)

      -- explode
      local explode_expected = {
        type = "explode_many",
        parser = "explode",
        values = {
          { value = 4, operator = "=" },
          {
            type = "roll",
            value = 20,
            operator = "=",
            roll = {
              quantity = 2,
              sides = 8,
            }
          }
        }
      }
      -- remove values we do don't care about for easier compare
      result.explode.rest = nil
      result.explode.values = _t.map(result.explode.values, function(item)
        item.rest = nil
        item.parser = nil
        return item
      end)

      assert.are.same(explode_expected, result.explode)

      assert.equal("", result.rest)
    end)
  end)
end)
