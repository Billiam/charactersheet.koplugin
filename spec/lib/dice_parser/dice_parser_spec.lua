local parser = require("charsheet/lib/dice_parser/parser")
local dice = require("charsheet/lib/dice_parser/dice_parser")
local _t = require("charsheet/lib/table_util")

describe("dice", function()
  describe("keep", function()
    it("matches keep highest", function()
      local result = dice.keep()("K")
      assert.equal("keep", result.parser)
      assert.equal("keep_highest", result.keep)
    end)

    it("matches keep highest with count", function()
      local result = dice.keep()("K3")
      assert.equal("keep", result.parser)
      assert.equal("keep_highest", result.keep)
      assert.equal(3, result.keep_count)
    end)

    it("matches keep lowest", function()
      local result = dice.keep()("KL")
      assert.equal("keep", result.parser)
      assert.equal("keep_lowest", result.keep)
    end)

    it("matches keep lowest with count", function()
      local result = dice.keep()("KL3")
      assert.equal("keep", result.parser)
      assert.equal("keep_lowest", result.keep)
      assert.equal(3, result.keep_count)
    end)

    it("matches keep highest", function()
      local result = dice.keep()("KM")
      assert.equal("keep", result.parser)
      assert.equal("keep_middle", result.keep)
    end)

    it("matches keep highest with count", function()
      local result = dice.keep()("KM3")
      assert.equal("keep", result.parser)
      assert.equal("keep_middle", result.keep)
      assert.equal(3, result.keep_count)
    end)
  end)

  describe("drop", function()
    it("matches drop highest", function()
      local result = dice.drop()("H")

      assert.equal("drop", result.parser)
      assert.equal("drop_highest", result.drop)
    end)

    it("matches drop highest with count", function()
      local result = dice.drop()("H3")
      assert.equal("drop", result.parser)
      assert.equal("drop_highest", result.drop)
      assert.equal(3, result.drop_count)
    end)

    it("matches drop lowest", function()
      local result = dice.drop()("L")

      assert.equal("drop", result.parser)
      assert.equal("drop_lowest", result.drop)
    end)

    it("matches drop lowest with count", function()
      local result = dice.drop()("L3")
      assert.equal("drop", result.parser)
      assert.equal("drop_lowest", result.drop)
      assert.equal(3, result.drop_count)
    end)

    describe("drop conditionally", function()
      it("returns drop conditions", function()
        local result = dice.drop()("D{<3}")
        assert.equal("drop", result.parser)
        assert.equal("drop_condition", result.drop)
        assert.are.same({ { value = 3, operator = "<" } }, result.drop_conditions)
      end)

      it("returns multiple drop conditions", function()
        local result = dice.drop()("D{<2,4,>5,>=6}")
        assert.equal("drop", result.parser)
        assert.equal("drop_condition", result.drop)
        assert.are.same(
          {
            { value = 2, operator = "<" },
            { value = 4, operator = "=" },
            { value = 5, operator = ">" },
            { value = 6, operator = ">=" }
          },
          result.drop_conditions)
      end)
    end)
  end)

  describe("clamp", function()
    it("returns minimum clamp conditions", function()
      local result = dice.clamp()("C<2")

      assert.equal("clamp", result.parser)
      assert.are.same({ min = 2, }, result.clamp)
    end)

    it("returns maximum clamp conditions", function()
      local result = dice.clamp()("C>5")

      assert.equal("clamp", result.parser)
      assert.are.same({ max = 5, }, result.clamp)
    end)

    it("returns range clamp conditions", function()
      local result = dice.clamp()("C<2>5")

      assert.equal("clamp", result.parser)
      assert.are.same({ min = 2, max = 5 }, result.clamp)
    end)
  end)

  -- TODO: should modifiers use a table with keys, or an array of types?
  describe("unique", function()
    it("return a unique flag", function()
      local result = dice.unique()("U")

      assert.equal("unique", result.parser)
      assert.are.same({}, result.unique)
    end)

    it("returns non-rerolled conditions", function()
      local result = dice.unique()("U{5}")

      assert.equal("unique", result.parser)
      assert.are.same({ 5 }, result.unique)
    end)
  end)

  describe("replacement", function()
    it("returns a direct value map", function()
      local result = dice.valueReplacement()("V{4=6,5=6}")

      assert.equal("value_replacement", result.parser)
      assert.are.same(
        {
          { value = 4, replacement = 6, condition = "=" },
          { value = 5, replacement = 6, condition = "=" }
        },
        result.replacement
      )
    end)

    it("returns ranged value map", function()
      local result = dice.valueReplacement()("V{<5=0,>15=20}")

      assert.equal("value_replacement", result.parser)
      assert.are.same(
        {
          { value = 5,  replacement = 0,  condition = "<" },
          { value = 15, replacement = 20, condition = ">" }
        },
        result.replacement
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
            replacement = {
              type = "random",
              from = 10,
              to = 20
            }
          }
        },
        result.replacement
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
            replacement = {
              type = "roll",
              quantity = 2,
              sides = 6
            }
          }
        },
        result.replacement
      )
    end)
  end)

  describe("explode", function()
    it("matches explosion", function()
      local result = dice.explode()("!")

      assert.equal("explode", result.parser)
      assert.equal("explode_many", result.explode_type)
      assert.are.same({}, result.explode)
    end)

    it("explodes extra dice", function()
      local result = dice.explode()("!3")

      assert.equal(3, result.explode_count)
    end)

    it("explodes on selectable values", function()
      local result = dice.explode()("!{<2,6}")

      assert.are.same({ value = 2, operator = "<" }, result.explode[1])
      assert.are.same({ value = 6, operator = "=" }, result.explode[2])
    end)

    it("explodes with a new roll", function()
      local result = dice.explode()("!{20=[2d6]}")

      local condition = result.explode[1]
      assert.equal("roll", condition.type)
      assert.equal(20, condition.value)
      assert.equal(6, condition.sides)
      assert.equal(2, condition.quantity)
      assert.equal("=", condition.operator)
    end)

    it("matches explode once", function()
      local result = dice.explode()("!!")

      assert.equal("explode", result.parser)
      assert.equal("explode_once", result.explode_type)
      assert.are.same({}, result.explode)
    end)

    it("matches reducing explosion", function()
      local result = dice.explode()("!!!")

      assert.equal("explode", result.parser)
      assert.equal("explode_reduced", result.explode_type)
      assert.are.same({}, result.explode)
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
      assert.equal(2, result.reroll_limit)
      assert.are.same({
        { value = 2, operator = "=" },
        { value = 5, operator = ">" },
      }, result.reroll_conditions)
    end)
  end)

  describe("count", function()
    it("matches count", function()
      local result = dice.count()("#")

      assert.equal("count", result.parser)
      assert.are.same({}, result.count)
    end)

    it("supports count conditions", function()
      local result = dice.count()("#{<4,5}")

      assert.equal("count", result.parser)
      assert.are.same({
        { value = 4, operator = "<" },
        { value = 5, operator = "=" },
      }, result.count)
    end)
  end)
end)
