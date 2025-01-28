local parser = require("charsheet/lib/dice_parser/parser")
local dice = require("charsheet/lib/dice_parser/dice_parser")
local _t = require("charsheet/lib/table_util")

describe("dice", function()
  describe("keep", function()
    it("matches keep highest", function()
      local result = dice.keep()("K")

      assert.includes({
        rest = "",
        parser = "keep",
        high = 1
      }, result)
    end)

    it("matches keep highest with count", function()
      local result = dice.keep()("K3")

      assert.includes({
        rest = "",
        parser = "keep",
        high = 3
      }, result)
    end)

    it("matches keep lowest", function()
      local result = dice.keep()("KL")

      assert.includes({
        rest = "",
        parser = "keep",
        low = 1
      }, result)
    end)

    it("matches keep lowest with count", function()
      local result = dice.keep()("KL3")

      assert.includes({
        rest = "",
        parser = "keep",
        low = 3
      }, result)
    end)

    it("matches keep middle", function()
      local result = dice.keep()("KM")

      assert.includes({
        rest = "",
        parser = "keep",
        middle = 1
      }, result)
    end)

    it("matches keep middle with count", function()
      local result = dice.keep()("KM3")

      assert.includes({
        rest = "",
        parser = "keep",
        middle = 3
      }, result)
    end)
  end)

  describe("drop", function()
    it("matches drop highest", function()
      local result = dice.drop()("H")
      assert.includes({
        rest = "",
        parser = "drop",
        high = 1
      }, result)
    end)

    it("matches drop highest with count", function()
      local result = dice.drop()("H3")
      assert.includes({
        rest = "",
        parser = "drop",
        high = 3
      }, result)
    end)

    it("matches drop lowest", function()
      local result = dice.drop()("L")

      assert.includes({
        rest = "",
        parser = "drop",
        low = 1
      }, result)
    end)

    it("matches drop lowest with count", function()
      local result = dice.drop()("L3")

      assert.equal("drop", result.type)
      assert.includes({
        rest = "",
        parser = "drop",
        low = 3
      }, result)
    end)

    describe("drop conditionally", function()
      it("returns drop conditions", function()
        local result = dice.drop()("D{<3}")

        assert.includes({
          rest = "",
          parser = "drop",
          values = {
            { value = 3, operator = "<" }
          }
        }, result)
      end)

      it("returns multiple drop conditions", function()
        local result = dice.drop()("D{<2,4,>5,>=6}")

        assert.includes({
          rest = "",
          parser = "drop",
          values = {
            { value = 2, operator = "<" },
            { value = 4, operator = "=" },
            { value = 5, operator = ">" },
            { value = 6, operator = ">=" }
          }
        }, result)
      end)
    end)
  end)

  describe("clamp", function()
    it("returns minimum clamp conditions", function()
      local result = dice.clamp()("C<2")

      assert.includes({
        rest = "",
        parser = "clamp",
        min = 2,
      }, result)
    end)

    it("returns maximum clamp conditions", function()
      local result = dice.clamp()("C>5")

      assert.includes({
        rest = "",
        parser = "clamp",
        max = 5
      }, result)
    end)

    it("returns range clamp conditions", function()
      local result = dice.clamp()("C<2>5")

      assert.includes({
        rest = "",
        parser = "clamp",
        min = 2,
        max = 5
      }, result)
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

      assert.includes({
        rest = "",
        parser = "unique",
        values = {
          { value = 5, operator = "=" }
        }
      }, result)
    end)
  end)

  describe("replacement", function()
    it("returns a direct value map", function()
      local result = dice.valueReplacement()("V{4=6,5=6}")

      assert.includes({
        rest = "",
        parser = "value_replacement",
        values = {
          { value = 4, type = "value", replacement = 6, operator = "=" },
          { value = 5, type = "value", replacement = 6, operator = "=" }
        }
      }, result)
    end)

    it("returns ranged value map", function()
      local result = dice.valueReplacement()("V{<5=0,>15=20}")

      assert.includes({
        rest = "",
        parser = "value_replacement",
        values = {
          { value = 5,  type = "value", replacement = 0,  operator = "<" },
          { value = 15, type = "value", replacement = 20, operator = ">" }
        }
      }, result)
    end)

    it("replaces values with random ranges", function()
      local result = dice.valueReplacement()("V{>5=10..20}")

      assert.includes({
        rest = "",
        parser = "value_replacement",
        values = {
          {
            value = 5,
            operator = ">",
            type = "range",
            replacement = {
              from = 10,
              to = 20
            }
          }
        }
      }, result)
    end)

    it("replaces values with new rolls", function()
      local result = dice.valueReplacement()("V{>5=[2d6]}")

      assert.includes({
        rest = "",
        parser = "value_replacement",
        values = {
          {
            value = 5,
            operator = ">",
            type = "die_roll",
            replacement = {
              quantity = 2,
              sides = 6
            }
          }
        }
      }, result)
    end)
  end)

  describe("explode", function()
    it("matches explosion", function()
      local result = dice.explode()("!")

      assert.includes({
        rest = "",
        parser = "explode",
        type = "explode_many",
        quantity = 1,
      }, result)
      assert.is_nil(result.values)
    end)

    it("explodes extra dice", function()
      local result = dice.explode()("!3")

      assert.includes({
        rest = "",
        quantity = 3
      }, result)
    end)

    it("explodes on selectable values", function()
      local result = dice.explode()("!{<2,6}")

      assert.includes({
        rest = "",
        values = {
          { value = 2, operator = "<" },
          { value = 6, operator = "=" }
        }
      }, result)
    end)

    it("explodes with a new roll", function()
      local result = dice.explode()("!{20=[2d6]}")
      assert.includes({
        rest = "",
        values = {
          {
            explodes_with = {
              type = "die_roll",
              sides = 6,
              quantity = 2,
            },
            value = 20,
            operator = "=",
          }
        }
      }, result)
    end)

    it("explodes on a roll pattern", function()
      local result = dice.explode()("!{(6,6,>5)}")

      assert.includes({
        rest = "",
        values = {
          {
            type = "pattern",
            values = {
              { value = 6, operator = "=" },
              { value = 6, operator = "=" },
              { value = 5, operator = ">" }
            }
          }
        }
      }, result)
    end)

    it("matches explode once", function()
      local result = dice.explode()("!!")

      assert.includes({
        rest = "",
        parser = "explode",
        type = "explode_once",
      }, result)
      assert.is_nil(result.values)
    end)

    it("matches reducing explosion", function()
      local result = dice.explode()("!!!")

      assert.includes({
        rest = "",
        parser = "explode",
        type = "explode_reduced",
      }, result)
      assert.is_nil(result.values)
    end)

    it("returns nil on error", function()
      local result = dice.explode()("{3,6}")

      assert.is_nil(result)
    end)
  end)

  describe("reroll", function()
    it("matches reroll conditions", function()
      local result = dice.reroll()("R{2,>5}2")

      assert.includes({
        rest = "",
        parser = "reroll",
        limit = 2,
        values = {
          { value = 2, operator = "=" },
          { value = 5, operator = ">" },
        }
      }, result)
    end)
  end)

  describe("count", function()
    it("matches count", function()
      local result = dice.count()("#")

      assert.includes({
        rest = "",
        parser = "count",
      }, result)
      assert.are.same({}, result.values)
    end)

    it("supports count conditions", function()
      local result = dice.count()("#{<4,5}")

      assert.includes({
        rest = "",
        parser = "count",
        values = {
          { value = 4, operator = "<" },
          { value = 5, operator = "=" },
        }
      }, result)
    end)
  end)

  describe("diceModifier", function()
    it("matches complex modifiers", function()
      local result = dice.dieModifier()("KL3H3L2D{<4}!{4,20=[2d8]}C<2U{5}#{<2,5}R{2}3V{>5=[2d6]}")

      assert.includes({
        rest = "",
        parser = "modifiers",
        drop = {
          high = 3,
          low = 2,
          values = {
            { operator = "<", value = 4, }
          }
        },
        keep = {
          low = 3
        },
        clamp = {
          min = 2
        },
        unique = {
          values = {
            { operator = "=", value = 5 }
          }
        },
        count = {
          values = {
            { value = 2, operator = "<" },
            { value = 5, operator = "=" },
          }
        },
        reroll = {
          limit = 3,
          values = {
            { value = 2, operator = "=" }
          }
        },
        value_replacement = {
          values = {
            {
              value = 5,
              type = "die_roll",
              replacement = {
                sides = 6,
                quantity = 2
              },
              operator = ">"
            }
          }
        },
        explode = {
          type = "explode_many",
          parser = "explode",
          values = {
            { value = 4, operator = "=" },
            {
              explodes_with = {
                type = "die_roll",
                quantity = 2,
                sides = 8,
              },
              value = 20,
              operator = "=",
            }
          }
        }
      }, result)
    end)
  end)

  describe("die", function()
    it("matches dice rolls", function()
      local result = dice.die()("2d20")

      assert.includes({
        rest = "",
        parser = "die",
        quantity = 2,
        sides = 20
      }, result)
    end)

    it("quantity is optional", function()
      local result = dice.die()("d6")

      assert.includes({
        rest = "",
        parser = "die",
        quantity = 1,
        sides = 6
      }, result)
    end)
  end)

  describe("dieRoll", function()
    it("matches rolls and modifiers", function()
      local result = dice.dieRoll()("2d20H")

      assert.includes({
        quantity = 2,
        sides = 20,
        modifiers = {
          drop = {
            high = 1
          }
        }
      }, result)
    end)
  end)

  describe("expression", function()
    it("parses basic arithmatic", function()
      local result = dice.expression()("1-2+3")

      assert.includes({
        rest = "",
        parser = "addition",
        values = {
          {
            operator = "+",
            value = {
              value = 1,
            }
          },
          {
            operator = "-",
            value = {
              value = 2,
            }
          },
          {
            operator = "+",
            value = {
              value = 3,
            }
          },
        }
      }, result)
    end)

    it("supports parentheses", function()
      local result = dice.expression()("1-(2+3)")

      assert.includes({
        rest = "",
        parser = "addition",
        values = {
          {
            operator = "+",
            value = {
              value = 1
            }
          },
          {
            operator = "-",
            value = {
              parser = "addition",
              values = {
                {
                  operator = "+",
                  value = {
                    value = 2
                  }
                },
                {
                  operator = "+",
                  value = {
                    value = 3
                  }
                }
              }
            }
          }
        }
      }, result)
    end)

    it("multiplication has higher precedence", function()
      local result = dice.expression()("1-2*3")

      assert.includes({
        parser = "addition",
        rest = "",
        values = {
          {
            operator = "+",
            value = {
              value = 1
            }
          },
          {
            operator = "-",
            value = {
              parser = "multiplication",
              values = {
                {
                  operator = "+",
                  value = {
                    value = 2
                  }
                },
                {
                  operator = "*",
                  value = {
                    value = 3
                  }
                }
              }
            }
          }
        }
      }, result)
    end)

    it("parses dice rolls", function()
      local result = dice.expression()("d6+1")

      assert.includes({
        rest = "",
        parser = "addition",
        values = {
          {
            value = {
              type = "die_roll",
              quantity = 1,
              sides = 6,
            }
          },
          {
            operator = "+",
            value = {
              value = 1,
            }
          }
        }
      }, result)
    end)
  end)
end)
