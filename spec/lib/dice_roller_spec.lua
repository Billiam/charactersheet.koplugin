local DiceRoller = require("charsheet/lib/dice_roller")
local dice = require("charsheet/lib/dice_parser/dice_parser")

describe("DiceRoller", function()
  local maxRandom = function(_, max) return max end
  local fixRolls = function(rolls)
    local i = 1
    return function(a, b)
      local result = rolls[i]
      if result == nil then
        error("Index " .. i .. " out bounds of defined rolls")
      end

      i = i + 1
      return result
    end
  end

  local sortedValues = function(rolls)
    local values = {}
    for i, roll in ipairs(rolls) do
      values[i] = roll.value
    end

    table.sort(values)
    return values
  end

  it("accepts a method for random dice rolls", function()
    local s = spy.new(function() return 1 end)
    DiceRoller:fromString("2d6", s):run()
    assert.spy(s).was_called(2)
    assert.spy(s).was_called_with(1, 6)
  end)

  it("performs simple arithmetic", function()
    assert.equal(6, DiceRoller:fromString("2-1+5"):run())
    assert.equal(-4, DiceRoller:fromString("2-(1+5)"):run())
  end)

  it("can roll dice", function()
    assert.equal(6, DiceRoller:fromString("1d6", maxRandom):run())
    assert.equal(40, DiceRoller:fromString("2d20", maxRandom):run())
  end)

  it("verify fixed result rolls", function()
    local rolls = fixRolls({ 1, 2, 3 })
    assert.equal(6, DiceRoller:fromString("3d100", rolls):run())
  end)

  it("performs math on dice rolls", function()
    assert.equal(32, DiceRoller:fromString("2-2d10+50", maxRandom):run())
  end)

  it("handles negative values", function()
    assert.equal(13, DiceRoller:fromString('-2+5-(-10)'):run())
  end)

  it("caches results in tree definition", function()
    local definition = dice.expression()("2+2d6")
    assert.is_nil(definition.values[2].value.roll_result)
    local _, new_definition = DiceRoller:new(definition, maxRandom):run()

    assert.are.same({
      { value = 6, sides = 6 },
      { value = 6, sides = 6 }
    }, new_definition.values[2].value.rolls)
    assert.equal(12, new_definition.values[2].value.roll_result)
  end)

  --it("supports dice modifiers", function()
  --  local rolls = fixRolls({ 25, 75 })
  --  local result, definition = DiceRoller:fromString("2d100K", rolls):run()
  --  assert.is_true(definition)
  --  assert.equal(75, result)
  --end)

  describe("dice modifiers", function()
    describe("keep", function()
      it("keeps middle rolls", function()
        local rolls = fixRolls({ 1, 2, 4 })
        local result = DiceRoller:fromString("3d20KM1", rolls):run()
        assert.equal(2, result)
      end)

      it("keeps middle rolls with even quantities", function()
        local rolls = fixRolls({ 1, 2, 4, 8 })
        local result = DiceRoller:fromString("4d20KM1", rolls):run()
        assert.equal(2, result)
      end)

      it("keeps highest rolls", function()
        local rolls = fixRolls({ 1, 2, 4, 8 })
        local result = DiceRoller:fromString("4d20K2", rolls):run()
        assert.equal(12, result)
      end)

      it("keeps lowest rolls", function()
        local rolls = fixRolls({ 1, 2, 4, 8 })
        local result = DiceRoller:fromString("4d20KL2", rolls):run()
        assert.equal(3, result)
      end)
    end)

    describe("drop", function()
      it("drops highest rolls", function()
        local rolls = fixRolls({ 1, 2, 4, 8 })
        local result = DiceRoller:fromString("4d20H2", rolls):run()
        assert.equal(3, result)
      end)

      it("drops lowest rolls", function()
        local rolls = fixRolls({ 1, 2, 4, 8 })
        local result = DiceRoller:fromString("4d20L2", rolls):run()
        assert.equal(12, result)
      end)

      it("drops lowest and highest rolls", function()
        local rolls = fixRolls({ 1, 2, 4, 8 })
        local result = DiceRoller:fromString("4d20HL", rolls):run()
        assert.equal(6, result)
      end)

      it("drops rolls conditionally", function()
        local rolls = fixRolls({ 1, 2, 4, 8 })
        local result = DiceRoller:fromString("4d20D{1,>=7}", rolls):run()
        assert.equal(6, result)
      end)
    end)

    describe("clamp", function()
      it("supports min and max roll clamping", function()
        local rolls = fixRolls({ 1, 8 })
        local result, definition = DiceRoller:fromString("2d8C<4>6", rolls):run()

        assert.are.same({
          { value = 4, sides = 8 },
          { value = 6, sides = 8 }
        }, definition.rolls)
        assert.equal(10, result)
      end)
    end)

    describe("count", function()
      it("counts maximum rolls by default", function()
        local rolls = fixRolls({ 1, 8, 4, 8 })
        local result, definition = DiceRoller:fromString("4d8#", rolls):run()
        assert.equal(2, result)
      end)

      it("counts rolls greater than a threshold", function()
        local rolls = fixRolls({ 1, 2, 4, 8 })
        local result, definition = DiceRoller:fromString("4d8#{4}", rolls):run()
        assert.equal(1, result)
      end)
    end)

    describe("value_replacement", function()
      it("replaces values with static values", function()
        local rolls = fixRolls({ 1, 2, 4, 8 })
        local result, definition = DiceRoller:fromString("4d8V{4=10}", rolls):run()

        assert.are.same({
          { value = 1,  sides = 8 },
          { value = 2,  sides = 8 },
          { value = 10, sides = 8, original_value = 4 },
          { value = 8,  sides = 8 }
        }, definition.rolls)
        assert.equal(21, result)
      end)

      it("replaces range conditions with static values", function()
        local rolls = fixRolls({ 1, 2, 4, 8 })
        local result, definition = DiceRoller:fromString("4d8V{>3=10}", rolls):run()

        assert.are.same({
          { value = 1,  sides = 8 },
          { value = 2,  sides = 8 },
          { value = 10, sides = 8, original_value = 4 },
          { value = 10, sides = 8, original_value = 8 }
        }, definition.rolls)
        assert.equal(23, result)
      end)

      it("replaces values with random values by range", function()
        local rolls = fixRolls({ 1, 2, 4, 8, 16 })
        local result, definition = DiceRoller:fromString("4d8V{2=10..20}", rolls):run()

        assert.are.same({
          { value = 1,  sides = 8 },
          { value = 16, sides = 8, original_value = 2 },
          { value = 4,  sides = 8 },
          { value = 8,  sides = 8 }
        }, definition.rolls)
        assert.equal(29, result)
      end)

      it("replaces values with the result of a dice roll", function()
        local rolls = fixRolls({ 1, 2, 4, 8, 3 })
        local result, definition = DiceRoller:fromString("4d8V{2=[1d4]}", rolls):run()

        assert.are.same({
          { value = 1, sides = 8 },
          { value = 3, sides = 8, original_value = 2 },
          { value = 4, sides = 8 },
          { value = 8, sides = 8 }
        }, definition.rolls)
        assert.equal(16, result)
      end)
    end)

    describe("reroll", function()
      it("rerolls selected values", function()
        local rolls = fixRolls({ 1, 2, 4, 8 })
        local definition = dice.expression()("3d8R{2}")
        local result, new_definition = DiceRoller:new(definition, rolls):run()

        assert.equals(13, result)
        assert.are.same({ 1, 4, 8 }, sortedValues(new_definition.rolls))
      end)

      it("rerolls selected ranges", function()
        local rolls = fixRolls({ 1, 2, 4, 1 })
        local definition = dice.expression()("3d8R{>3}")
        local result, new_definition = DiceRoller:new(definition, rolls):run()

        assert.equals(4, result)
        assert.are.same({ 1, 1, 2 }, sortedValues(new_definition.rolls))
      end)

      it("limits retries", function()
        local rolls = fixRolls({ 1, 3, 3, 3, 100 })
        local definition = dice.expression()("2d8R{3}2")
        local result, new_definition = DiceRoller:new(definition, rolls):run()

        assert.equals(4, result)
        assert.are.same({ 1, 3 }, sortedValues(new_definition.rolls))
      end)

      it("limits retries by default", function()
        local definition = dice.expression()("2d8R{8}")
        local result, new_definition = DiceRoller:new(definition, maxRandom):run()

        assert.equals(16, result)
        assert.are.same({ 8, 8 }, sortedValues(new_definition.rolls))
      end)
    end)

    describe("unique", function()
      it("does not affect rolls when pool is unique", function()
        local rolls = fixRolls({ 1, 2, 4, 8, 300 })
        local definition = dice.expression()("4d8U")
        local result = DiceRoller:new(definition, rolls):run()

        assert.equals(15, result)
      end)

      it("rerolls non-unique values", function()
        local rolls = fixRolls({ 1, 2, 2, 4, 8 })
        local definition = dice.expression()("4d8U")
        local result = DiceRoller:new(definition, rolls):run()

        assert.equals(15, result)
      end)

      it("ignores specific values", function()
        local rolls = fixRolls({ 2, 2, 4, 4, 5 })
        local definition = dice.expression()("4d8U{2}")
        local result, new_definition = DiceRoller:new(definition, rolls):run()

        assert.equals(13, result)
        assert.are.same({ 2, 2, 4, 5 }, sortedValues(new_definition.rolls))
      end)

      it("ignores ranges", function()
        local rolls = fixRolls({ 2, 2, 4, 4, 5 })
        local definition = dice.expression()("4d8U{>3}")
        local result, new_definition = DiceRoller:new(definition, rolls):run()

        assert.equals(15, result)
        assert.are.same({ 2, 4, 4, 5 }, sortedValues(new_definition.rolls))
      end)

      it("limits infinite rerolls", function()
        local definition = dice.expression()("2d4U")
        local result = DiceRoller:new(definition, maxRandom):run()

        assert.equals(8, result)
      end)
    end)

    describe("explode", function()
      describe("explode_once", function()
        it("only explodes dice once", function()
          local definition = dice.expression()("2d4!!")

          local result, new_definition = DiceRoller:new(definition, maxRandom):run()

          assert.includes({
            { value = 4, exploded = true },
            { value = 4, exploded = true },
            { value = 4 },
            { value = 4 },
          }, new_definition.rolls)
          assert.equal(16, result)
        end)

        it("explodes with extra dice", function()
          local definition = dice.expression()("d4!!2")

          local result, new_definition = DiceRoller:new(definition, maxRandom):run()

          assert.includes({
            { value = 4, exploded = true },
            { value = 4 },
            { value = 4 },
          }, new_definition.rolls)
          assert.equal(12, result)
        end)

        it("explodes with custom rolls", function()
          local definition = dice.expression()("d4!!{4=[1d8]}")
          local result, new_definition = DiceRoller:new(definition, maxRandom):run()

          assert.are.same({
            { value = 4, sides = 4, exploded = true },
            { value = 8, sides = 8 },
          }, new_definition.rolls)
          assert.equal(12, result)
        end)

        it("explodes patterns once", function()
          local rolls = fixRolls({ 1, 3, 3, 2, 100, 10000 })
          local definition = dice.expression()("4d4!!{(3,3)}")
          local result = DiceRoller:new(definition, rolls):run()

          assert.equals(109, result)
        end)
      end)

      describe("explode_many", function()
        it("retains modifiers for explosion rolls", function()
          local rolls = fixRolls({ 4, 1 })
          local definition = dice.expression()("d4!C<2")
          local result = DiceRoller:new(definition, rolls):run()

          assert.same(6, result)
        end)

        it("does not retain modifiers for subexpression explosion rolls", function()
          local rolls = fixRolls({ 4, 1 })
          local definition = dice.expression()("d4!{4=[d4]}C<2")
          local result = DiceRoller:new(definition, rolls):run()

          assert.same(5, result)
        end)

        it("explodes on the maximum roll", function()
          local rolls = fixRolls({ 4, 4, 4, 4, 3, 4 })
          local definition = dice.expression()("d4!")
          local result = DiceRoller:new(definition, rolls):run()

          assert.equals(19, result)
        end)

        it("limits explosions to 1000 rounds", function()
          local definition = dice.expression()("2d4!")

          local result, new_definition = DiceRoller:new(definition, maxRandom):run()
          assert.equal(2002, #new_definition.rolls)
          assert.equal(8008, result)
        end)
      end)

      describe("explode_reduced", function()
        it("rolls reducing dice for each roll", function()
          local rolls = fixRolls({ 7, 5, 2, 2, 1, 1, 100 })

          local definition = dice.expression()("2d8!!!")
          local result, new_definition = DiceRoller:new(definition, rolls):run()

          assert.equal(18, result)
          assert.are_same({
            { value = 7, sides = 8, exploded = true },
            { value = 5, sides = 8, exploded = true },
            { value = 2, sides = 7, exploded = true },
            { value = 2, sides = 5, exploded = true },
            { value = 1, sides = 2 },
            { value = 1, sides = 2 },
          }, new_definition.rolls)
        end)
      end)
    end)
  end)
end)
