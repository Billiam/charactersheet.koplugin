local parser = require("charsheet/lib/dice_parser/parser")
local dice = require("charsheet/lib/dice_parser/dice_parser")
local _t = require("charsheet/lib/table_util")

describe("dice", function()
  describe("digits", function()
    it("matches integers", function()
      local result = dice.expression()("15")

      assert.includes({
        rest = "",
        type = "number",
        value = 15
      }, result)
    end)

    it("matches decimals", function()
      local result = dice.expression()("12.5")

      assert.includes({
        rest = "",
        type = "number",
        value = 12.5
      }, result)
    end)
  end)

  describe("keep", function()
    it("matches keep highest", function()
      local result = dice.keep()("K")

      assert.includes({
        rest = "",
        parser = "keep",
        high = {
          type = "number",
          value = 1
        }
      }, result)
    end)

    it("matches keep highest with count", function()
      local result = dice.keep()("K3")

      assert.includes({
        rest = "",
        parser = "keep",
        high = {
          type = "number",
          value = 3
        }
      }, result)
    end)

    it("matches keep lowest", function()
      local result = dice.keep()("KL")

      assert.includes({
        rest = "",
        parser = "keep",
        low = {
          type = "number",
          value = 1
        }
      }, result)
    end)

    it("matches keep lowest with count", function()
      local result = dice.keep()("KL3")

      assert.includes({
        rest = "",
        parser = "keep",
        low = {
          type = "number",
          value = 3
        }
      }, result)
    end)

    it("matches keep middle", function()
      local result = dice.keep()("KM")

      assert.includes({
        rest = "",
        parser = "keep",
        middle = {
          type = "number",
          value = 1
        }
      }, result)
    end)

    it("matches keep middle with count", function()
      local result = dice.keep()("KM3")

      assert.includes({
        rest = "",
        parser = "keep",
        middle = {
          type = "number",
          value = 3
        }
      }, result)
    end)
  end)

  describe("drop", function()
    it("matches drop highest", function()
      local result = dice.drop()("H")
      assert.includes({
        rest = "",
        parser = "drop",
        high = {
          type = "number",
          value = 1
        }
      }, result)
    end)

    it("matches drop highest with count", function()
      local result = dice.drop()("H3")
      assert.includes({
        rest = "",
        parser = "drop",
        high = {
          type = "number",
          value = 3
        }
      }, result)
    end)

    it("matches drop lowest", function()
      local result = dice.drop()("L")

      assert.includes({
        rest = "",
        parser = "drop",
        low = {
          type = "number",
          value = 1
        }
      }, result)
    end)

    it("matches drop lowest with count", function()
      local result = dice.drop()("L3")

      assert.equal("drop", result.type)
      assert.includes({
        rest = "",
        parser = "drop",
        low = {
          type = "number",
          value = 3
        }
      }, result)
    end)

    describe("drop conditionally", function()
      it("returns drop conditions", function()
        local result = dice.drop()("D{<3}")

        assert.includes({
          rest = "",
          parser = "drop",
          values = {
            {
              value = {
                type = "number",
                value = 3
              },
              operator = "<"
            }
          }
        }, result)
      end)

      it("returns multiple drop conditions", function()
        local result = dice.drop()("D{<2,4,>5,>=6}")

        assert.includes({
          rest = "",
          parser = "drop",
          values = {
            {
              value = {
                type = "number",
                value = 2
              },
              operator = "<"
            },
            {
              value = {
                type = "number",
                value = 4
              },
              operator = "="
            },
            {
              value = {
                type = "number",
                value = 5
              },
              operator = ">"
            },
            {
              value = {
                type = "number",
                value = 6
              },
              operator = ">="
            }
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
        min = {
          type = "number",
          value = 2
        },
      }, result)
    end)

    it("returns maximum clamp conditions", function()
      local result = dice.clamp()("C>5")

      assert.includes({
        rest = "",
        parser = "clamp",
        max = {
          type = "number",
          value = 5
        }
      }, result)
    end)

    it("returns range clamp conditions", function()
      local result = dice.clamp()("C<2>5")

      assert.includes({
        rest = "",
        parser = "clamp",
        min = {
          type = "number",
          value = 2
        },
        max = {
          type = "number",
          value = 5
        }
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
          {
            value = {
              type = "number",
              value = 5
            },
            operator = "="
          }
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
          {
            value = {
              type = "number",
              value = 4
            },
            type = "value",
            replacement = {
              type = "number",
              value = 6
            },
            operator = "="
          },
          {
            value = {
              type = "number",
              value = 5
            },
            type = "value",
            replacement = {
              type = "number",
              value = 6
            },
            operator = "="
          }
        }
      }, result)
    end)

    it("returns ranged value map", function()
      local result = dice.valueReplacement()("V{<5=0,>15=20}")

      assert.includes({
        rest = "",
        parser = "value_replacement",
        values = {
          {
            value = {
              type = "number",
              value = 5
            },
            type = "value",
            replacement = {
              type = "number",
              value = 0
            },
            operator = "<"
          },
          {
            value = {
              type = "number",
              value = 15
            },
            type = "value",
            replacement = {
              type = "number",
              value = 20
            },
            operator = ">"
          }
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
            value = {
              type = "number",
              value = 5
            },
            operator = ">",
            type = "range",
            replacement = {
              from = {
                type = "number",
                value = 10
              },
              to = {
                type = "number",
                value = 20
              }
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
            value = {
              type = "number",
              value = 5
            },
            operator = ">",
            type = "die_roll",
            replacement = {
              quantity = {
                type = "number",
                value = 2
              },
              sides = {
                type = "number",
                value = 6
              }
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
        quantity = {
          type = "number",
          value = 1
        },
      }, result)
      assert.is_nil(result.values)
    end)

    it("explodes extra dice", function()
      local result = dice.explode()("!3")

      assert.includes({
        rest = "",
        quantity = {
          type = "number",
          value = 3
        }
      }, result)
    end)

    it("explodes on selectable values", function()
      local result = dice.explode()("!{<2,6}")

      assert.includes({
        rest = "",
        values = {
          {
            value = {
              type = "number",
              value = 2
            },
            operator = "<"
          },
          {
            value = {
              type = "number",
              value = 6
            },
            operator = "="
          }
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
              sides = {
                type = "number",
                value = 6
              },
              quantity = {
                type = "number",
                value = 2
              },
            },
            value = {
              type = "number",
              value = 20
            },
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
              {
                value = {
                  type = "number",
                  value = 6
                },
                operator = "="
              },
              {
                value = {
                  type = "number",
                  value = 6
                },
                operator = "="
              },
              {
                value = {
                  type = "number",
                  value = 5
                },
                operator = ">"
              }
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
        limit = {
          type = "number",
          value = 2
        },
        values = {
          {
            value = {
              type = "number",
              value = 2
            },
            operator = "="
          },
          {
            value = {
              type = "number",
              value = 5
            },
            operator = ">"
          },
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
          {
            value = {
              type = "number",
              value = 4
            },
            operator = "<"
          },
          {
            value = {
              type = "number",
              value = 5
            },
            operator = "="
          },
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
          high = {
            type = "number",
            value = 3
          },
          low = {
            type = "number",
            value = 2
          },
          values = {
            {
              operator = "<",
              value = {
                type = "number",
                value = 4
              },
            }
          }
        },
        keep = {
          low = {
            type = "number",
            value = 3
          }
        },
        clamp = {
          min = {
            type = "number",
            value = 2
          }
        },
        unique = {
          values = {
            {
              operator = "=",
              value = {
                type = "number",
                value = 5
              }
            }
          }
        },
        count = {
          values = {
            {
              value = {
                type = "number",
                value = 2
              },
              operator = "<"
            },
            {
              value = {
                type = "number",
                value = 5
              },
              operator = "="
            },
          }
        },
        reroll = {
          limit = {
            type = "number",
            value = 3
          },
          values = {
            {
              value = {
                type = "number",
                value = 2
              },
              operator = "="
            }
          }
        },
        value_replacement = {
          values = {
            {
              value = {
                type = "number",
                value = 5
              },
              type = "die_roll",
              replacement = {
                sides = {
                  type = "number",
                  value = 6
                },
                quantity = {
                  type = "number",
                  value = 2
                }
              },
              operator = ">"
            }
          }
        },
        explode = {
          type = "explode_many",
          parser = "explode",
          values = {
            {
              value = {
                type = "number",
                value = 4
              },
              operator = "="
            },
            {
              explodes_with = {
                type = "die_roll",
                quantity = {
                  type = "number",
                  value = 2
                },
                sides = {
                  type = "number",
                  value = 8
                },
              },
              value = {
                type = "number",
                value = 20
              },
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
        quantity = {
          type = "number",
          value = 2
        },
        sides = {
          type = "number",
          value = 20
        }
      }, result)
    end)

    it("quantity is optional", function()
      local result = dice.die()("d6")

      assert.includes({
        rest = "",
        parser = "die",
        quantity = {
          type = "number",
          value = 1
        },
        sides = {
          type = "number",
          value = 6
        }
      }, result)
    end)
  end)

  describe("dieRoll", function()
    it("matches rolls and modifiers", function()
      local result = dice.dieRoll()("2d20H")

      assert.includes({
        quantity = {
          type = "number",
          value = 2
        },
        sides = {
          type = "number",
          value = 20
        },
        modifiers = {
          drop = {
            high = {
              type = "number",
              value = 1
            }
          }
        }
      }, result)
    end)
  end)

  describe("method", function()
    local methods = { "abs", "acos", "asin", "atan", "ceil", "cos", "floor", "round", "sign", "sin", "sqrt", "tan" }
    for _, method in ipairs(methods) do
      describe(method, function()
        it("matches method usage", function()
          local result = dice.method()(method .. "(1.5)")
          assert.includes({
            rest = "",
            type = "method",
            method = method,
            values = {
              {
                type = "number",
                value = 1.5,
              }
            }
          }, result)
        end)

        it("requires arguments", function()
          assert.is_nil(dice.method()(method .. "()"))
        end)
      end)
    end
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

    it("parses exponents", function()
      local result = dice.expression()("5*2^3")

      assert.includes({
        rest = "",
        type = "multiplication",
        values = {
          {
            operator = "+",
            value = {
              value = 5
            }
          },
          {
            operator = "*",
            value = {
              type = "exponentiation",
              values = {
                {
                  operator = "+",
                  value = {
                    value = 2
                  }
                },
                {
                  operator = "^",
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

    describe("variables", function()
      it("supports variables", function()
        local result = dice.expression()("2+{{strength}}")
        assert.includes({
          type = "addition",
          values = {
            {
              operator = "+",
              value = {
                type = "number",
                value = 2
              }
            },
            {
              operator = "+",
              value = {
                type = "variable",
                values = {
                  "strength"
                }
              }
            }
          }
        }, result)
      end)

      it("supports variables in place of dice roll components", function()
        local result = dice.expression()("{{q}}d{{sides}}")

        assert.equal("", result.rest)
        assert.includes({
          type = "die_roll",
          quantity = {
            type = "variable",
            values = { "q" }
          },
          sides = {
            type = "variable",
            values = { "sides" }
          }
        }, result)
      end)

      it("returns a list for nested values", function()
        local result = dice.expression()("{{a.b.c}}")
        assert.includes({
          type = "variable",
          values = { "a", "b", "c" }
        }, result)
      end)
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
              quantity = {
                type = "number",
                value = 1
              },
              sides = {
                type = "number",
                value = 6
              }
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
