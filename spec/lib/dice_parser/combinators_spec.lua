local _c = require("charsheet/lib/dice_parser/combinators")
local dump = require("charsheet/lib/dump")

describe("combinators", function()
  describe("literal", function()
    it("returns matching values", function()
      local foo = _c.literal("foo")
      local result = foo("food truck")

      assert.equal("foo", result.value)
      assert.equal("d truck", result.rest)
      assert.equal("literal", result.parser)
    end)

    it("returns nil on failure", function()
      local asdf = _c.literal("asdf")
      local result = asdf("food truck")

      assert.is_nil(result)
    end)
  end)

  describe("match", function()
    it("returns pattern matched value", function()
      local digits = _c.match("^%d+")
      local result = digits("1234abcd")

      assert.equal("1234", result.value)
      assert.equal("abcd", result.rest)
      assert.equal("match", result.parser)
    end)

    it("returns nil on failure", function()
      local digits = _c.match("^%d+")
      local result = digits("abcd")

      assert.is_nil(result)
    end)

    it("treats all matching as anchored", function()
      local digits = _c.match("%d+")
      local result = digits("abcd1234")
      assert.is_nil(result)
    end)
  end)

  describe("any", function()
    it("matches if any arguments match", function()
      local e = _c.literal("e")
      local f = _c.literal("f")
      local g = _c.literal("g")

      local letters = _c.any(e, f, g)
      local result = letters("fruit")

      assert.equal("f", result.value)
      assert.equal("ruit", result.rest)
    end)

    it("returns nil on failure", function()
      local letters = _c.any(_c.literal("e"), _c.literal("f"), _c.literal("g"))
      local result = letters("vegetables")

      assert.is_nil(result)
    end)
  end)

  describe("optional", function()
    it("matches when argument matches", function()
      local optional_foo = _c.optional(_c.literal("foo"))
      local result = optional_foo("food truck")

      assert.equal("foo", result.value)
      assert.equal("d truck", result.rest)
    end)

    it("returns an empty result on failure", function()
      local optional_foo = _c.optional(_c.literal("foo"))
      local result = optional_foo("Delaware")

      assert.is_nil(result.value)
      assert.equal("Delaware", result.rest)
    end)

    it("treats strings as parser literals", function()
      local result = _c.optional("foo")("food truck")

      assert.equal("foo", result.value)
    end)
  end)

  describe("capture", function()
    it("saves value to named key on success", function()
      local capture_foo = _c.capture("my_match", _c.literal("foo"))
      local result = capture_foo("food truck")

      assert.equal("foo", result.value)
      assert.equal("d truck", result.rest)
      assert.equal("foo", result.captures.my_match)
    end)

    it("maps matching value", function()
      local reverse = function(str)
        return str:reverse()
      end

      local capture_foo = _c.capture("my_match", _c.literal("foo"), reverse)
      local result = capture_foo("food truck")

      assert.equal("foo", result.value)
      assert.equal("d truck", result.rest)
      assert.equal("oof", result.captures.my_match)
    end)

    it("appends to existing captures", function()
      local fixed_capture = {
        value = "foo",
        rest = "d truck",
        captures = {
          food = "burrito"
        }
      }
      local make_capture = function()
        return fixed_capture
      end

      local capture = _c.capture("new_value", make_capture)

      local result = capture("")
      assert.equal("foo", result.value)
      assert.equal("d truck", result.rest)
      assert.equal("burrito", result.captures.food)
      assert.equal("foo", result.captures.new_value)
    end)

    it("does not mutate existing capture object", function()
      local fixed_capture = {
        value = "foo",
        rest = "d truck",
        captures = {
          food = "burrito"
        }
      }
      local make_capture = function()
        return fixed_capture
      end

      local capture = _c.capture("new_value", make_capture)

      local result = capture("")
      assert.equal("foo", result.captures.new_value)
      assert.equal("burrito", fixed_capture.captures.food)
      assert.is_nil(fixed_capture.captures.new_value)
    end)

    it("overrides existing captures with the same name", function()
      local fixed_capture = {
        value = "foo",
        rest = "d truck",
        captures = {
          food = "burrito"
        }
      }
      local make_capture = function()
        return fixed_capture
      end

      local capture = _c.capture("food", make_capture)

      local result = capture("")
      assert.equal("foo", result.captures.food)
    end)

    it("accepts an alternate key to capture", function()
      local fixed_capture = {
        value = "foo",
        rest = "d truck",
        captures = {
          food = "burrito"
        }
      }
      local make_capture = function()
        return fixed_capture
      end

      local capture = _c.capture("food", "rest", make_capture)

      local result = capture("")
      assert.equal("d truck", result.captures.food)
    end)

    it("returns nil on failure", function()
      local capture_foo = _c.capture("my_match", _c.literal("foo"))
      local result = capture_foo("Deleware")

      assert.is_nil(result)
    end)
  end)

  describe("captureValues", function()
    it("moves result values to a capture", function()
      local previous_result = {
        value = "value",
        rest = "",
        values = { 1, 2, 3 }
      }
      local result_builder = function()
        return previous_result
      end

      local capturer = _c.captureValues("my_capture", result_builder)
      local result = capturer("")

      assert.are.same({ 1, 2, 3 }, result.captures.my_capture)
      assert.equal("value", result.value)
      assert.equal("", result.rest)
    end)
  end)

  describe("concatenate", function()
    it("combines value properties", function()
      local fixed_result = function()
        return {
          values = {
            { value = "a" },
            { value = "b" },
            { value = "c" }
          }
        }
      end

      local concat = _c.concatenate(fixed_result)
      local result = concat("")

      assert.equal("abc", result.value)
    end)
  end)

  describe("dropLeftValue", function()
    it("removes the first values", function()
      local fixed_result = function()
        return {
          values = {
            { value = "a" },
            { value = "b" },
            { value = "c" }
          },
          rest = "more"
        }
      end
      local drop = _c.dropLeftValue(2, fixed_result)
      local result = drop("")

      assert.are.same({ values = { { value = "c" } }, rest = "more" }, result)
    end)
  end)

  describe("map", function()
    it("modifies results on match", function()
      local reverse = function(result)
        result.value = result.value:reverse()
        result.other = "other"

        return result
      end

      local reversing_match = _c.map(_c.literal("food"), reverse)
      local result = reversing_match("food truck")
      assert.equal("doof", result.value)
      assert.equal("other", result.other)
    end)

    it("returns nil on failure", function()
      local matcher = _c.map(_c.literal("food"), function() end)
      local result = matcher("delivery")

      assert.is_nil(result)
    end)
  end)

  describe("sequence", function()
    it("matches when all parsers match", function()
      local food = _c.sequence(_c.literal("f"), _c.literal("o"), _c.literal("od"))
      local result = food("food truck")

      assert.equal("f", result.values[1].value)
      assert.equal("o", result.values[2].value)
      assert.equal("od", result.values[3].value)

      assert.equal(" truck", result.rest)
    end)

    it("only matches when parsers appear in the correct order", function()
      local food = _c.sequence(_c.literal("f"), _c.literal("o"), _c.literal("o"), _c.literal("d"))
      local result = food("fodo")

      assert.is_nil(result)
    end)

    it("treats strings like literal parsers", function()
      local food = _c.sequence("f", "o", "od")
      local result = food("food truck")


      assert.equal("f", result.values[1].value)
      assert.equal("o", result.values[2].value)
      assert.equal("od", result.values[3].value)

      assert.equal(" truck", result.rest)
    end)

    it("returns nil on on failure", function()
      local food = _c.sequence(_c.literal("f"), _c.literal("o"), _c.literal("o"), _c.literal("d"))
      local result = food("foobar")

      assert.is_nil(result)
    end)
  end)

  describe("nOrMore", function()
    it("matches more than one repeat", function()
      local repeats = _c.nOrMore(2, _c.sequence(_c.literal("a"), _c.literal("b")))
      local result = repeats("abababacacac")

      assert.equal(3, #result.values)
      assert.equal("acacac", result.rest)
    end)

    it("must meet the minimum repeat count", function()
      local repeats = _c.nOrMore(3, _c.sequence(_c.literal("a"), _c.literal("b")))
      local result = repeats("abab")

      assert.is_nil(result)
    end)

    it("treats string parsers as literals", function()
      local repeats = _c.nOrMore(2, "a")
      local result = repeats("aaabbb")

      assert.equal(3, #result.values)
      assert.equal("bbb", result.rest)
    end)
  end)

  describe("nOrMoreUnique", function()
    it("matches more than one repeat", function()
      local unique_repeats = _c.nOrMoreUnique(2, _c.literal("a"), _c.literal("b"), _c.literal("c"))
      local result = unique_repeats("cbacba")

      assert.equal("cba", result.rest)
      assert.equal(3, #result.values)
    end)

    it("treats strings as literal parsers", function()
      local unique_repeats = _c.nOrMoreUnique(2, "a", "b", "c")
      local result = unique_repeats("cbacba")

      assert.equal("cba", result.rest)
      assert.equal(3, #result.values)
    end)

    it("must meet the minimum repeat count", function()
      local unique_repeats = _c.nOrMoreUnique(3, _c.literal("a"), _c.literal("b"), _c.literal("c"))
      local result = unique_repeats("ababab")

      assert.is_nil(result)
    end)
  end)

  describe("between", function()
    it("matches values between delimeters", function()
      local tag = _c.between(_c.literal("<"), _c.literal(">"), _c.match("[^>]+"))
      local result = tag("<content> other")

      assert.equal("content", result.value)
      assert.equal(" other", result.rest)
    end)

    it("returns nil on failure", function()
      local tag = _c.between(_c.literal("<"), _c.literal(">"), _c.match("[^>]+"))
      local result = tag("<content")

      assert.is_nil(result)
    end)
  end)

  describe("list", function()
    it("matches repeated items", function()
      local comma_separated = _c.list(_c.literal(","), _c.match("%d+"))
      local result = comma_separated("21,42,53,")

      assert.equal("21", result.values[1].value)
      assert.equal("42", result.values[2].value)
      assert.equal("53", result.values[3].value)

      assert.equal("", result.rest)
    end)

    it("treats strings as literal parsers", function()
      local comma_separated = _c.list(",", "b")
      local result = comma_separated("b,b,b")

      assert.equal("b", result.values[1].value)
      assert.equal("b", result.values[2].value)
      assert.equal("b", result.values[3].value)
    end)

    it("the last delimiter is optional", function()
      local comma_separated = _c.list(_c.literal(","), _c.match("%d+"))
      local result = comma_separated("21,42,53")

      assert.equal("21", result.values[1].value)
      assert.equal("42", result.values[2].value)
      assert.equal("53", result.values[3].value)
      assert.equal("", result.rest)
    end)

    it("matches a single value without a delimiter", function()
      local comma_separated = _c.list(_c.literal(","), _c.match("%d+"))
      local result = comma_separated("21")

      assert.equal("21", result.values[1].value)
      assert.equal("", result.rest)
    end)
  end)

  describe("ignore", function()
    it("clears the result value", function()
      local passthrough_parser = function(str)
        return {
          value = str,
          rest = "rest"
        }
      end

      local ignored = _c.ignore(passthrough_parser)
      local result = ignored("hello")

      assert.is_nil(result.value)
      assert.equal("rest", result.rest)
    end)

    it("treats strings as literal parsers", function()
      local ignored = _c.ignore("hell")
      local result = ignored("hello")

      assert.is_nil(result.value)
      assert.equal("o", result.rest)
    end)

    it("return nil on failure", function()
      local ignored = _c.ignore(_c.literal('a'))
      local result = ignored("b")

      assert.is_nil(result)
    end)
  end)

  describe("nthValue", function()
    it("returns result values by index", function()
      local values_parser = function()
        return {
          value = "original_value",
          values = { { value = "a" }, { value = "b" } },
          rest = "rest"
        }
      end
      local second_value = _c.nthValue(2, values_parser)
      local result = second_value("")

      assert.equal("b", result.value)
      assert.equal("rest", result.rest)
    end)

    it("returns nil on failure", function()
      local ignored = _c.nthValue(2, _c.literal('a'))
      local result = ignored("b")

      assert.is_nil(result)
    end)
  end)

  describe("stripWhitespace", function()
    it("removes whitespace from the input", function()
      local strip = _c.stripWhitespace()
      local result = strip("a b c d ")

      assert.equal("abcd", result.rest)
    end)
  end)
end)
