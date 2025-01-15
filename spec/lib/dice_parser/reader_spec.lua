local Reader = require("charsheet/lib/dice_parser/reader")

describe("Reader", function()
  describe("peek", function()
    it("reads characters without advancing", function()
      local reader = Reader:new("hello")

      assert.equal("hel", reader:peek(3))
      assert.equal("hel", reader:peek(3))
    end)
  end)

  describe("read", function()
    it("reads characters while advancing", function()
      local reader = Reader:new("hello")

      assert.equal("h", reader:read(1))
      assert.equal("el", reader:read(2))
      assert.equal("lo", reader:read(2))
    end)
  end)

  describe("eof", function()
    it("returns false prior to the end of string", function()
      local reader = Reader:new("hello")
      assert.is_false(reader:eof())

      reader:read(5)
      assert.is_true(reader:eof())
    end)
  end)

  describe("match", function()
    it("returns matching string", function()
      local reader = Reader:new("1234abcd")

      local match = reader:match("^%d+")
      assert.is_equal("1234", match)
    end)

    it("advances on a match", function()
      local reader = Reader:new("1234abcd")

      reader:match("^%d+")
      assert.is_equal("abcd", reader:read(4))
    end)

    it("does not advance on failed match", function()
      local reader = Reader:new("1234abcd")

      assert.is_nil(reader:match("^%a+"))
      assert("1234abcd", reader:read(8))
    end)

    it("does not advance when advance argument is disabled", function()
      local reader = Reader:new("1234abcd")

      reader:match("^%d+", false)
      assert.is_equal("1234", reader:read(4))
    end)
  end)

  describe("skipWhitespace", function()
    it("advances on whitespace", function()
      local reader = Reader:new("    abcd")

      reader:skipWhitespace()
      assert.is_equal("abcd", reader:read(4))
    end)

    it("does not advance on non-whitespace characters", function()
      local reader = Reader:new("1234abcd")

      reader:skipWhitespace()
      assert.is_equal("1234abcd", reader:read(8))
    end)
  end)

  describe("cur", function()
    it("returns the current character", function()
      local reader = Reader:new("1234abcd")
      assert.is_equal("1", reader:cur())
    end)

    it("does not advance the reader", function()
      local reader = Reader:new("1234abcd")
      assert.is_equal("1", reader:cur())
      assert.is_equal("1", reader:cur())
    end)
  end)
end)
