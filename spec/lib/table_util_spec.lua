local table_util = require("charsheet/lib/table_util")
describe("table_util", function()
  describe("dig", function()
    it("fetches nested table values", function()
      local t = {
        a = {
          b = {
            10,
            20,
            30,
          }
        }
      }
      assert.are.equal(30, table_util.dig(t, "a", "b", 3))
    end)

    it("returns nil for missing values", function()
      local t = {
        a = {
          b = {
            10,
            20,
            30,
          }
        }
      }
      assert.is_nil(table_util.dig(t, "a", "c", 3))
    end)
  end)

  describe("contains", function()
    it("compares object equality", function()
      local subtable = { 1, 2, 3 }
      local t = { "a", "b", subtable }

      assert.is_true(table_util.contains(t, "b"))
      assert.is_true(table_util.contains(t, subtable))
      assert.is_false(table_util.contains(t, "c"))
      assert.is_false(table_util.contains(t, { 1, 2, 3 }))
    end)
  end)

  describe("clone", function()
    it("performs a shallow clone of a table", function()
      local outer = {
        inner = {}
      }
      local result = table_util.clone(outer)
      assert.are_same(outer, result)
      assert.are_not.equal(outer, result)
      assert.equal(outer.inner, result.inner)
    end)

    it("performs a deep clone of a table", function()
      local outer = {
        inner = {
          innermost = {}
        }
      }
      local result = table_util.clone(outer, true)

      assert.are_same(outer, result)
      assert.are_not.equal(outer, result)
      assert.are_not.equal(outer.inner, result.inner)
      assert.are_not.equal(outer.inner.innermost, result.inner.innermost)
    end)
  end)

  describe("find", function()
    it("returns the first matching element", function()
      local result = table_util.find({ "a", "b", "c", "d" }, "c")
      assert.equal(3, result)
    end)
    it("find elements by mapped value", function()
      local input = { 1, 2, 3 }
      local result = table_util.find(input, 4, function(i) return i * 2 end)
      assert.equal(2, result)
    end)
    it("finds tables by identity", function()
      local a = {}
      local b = {}
      local c = {}
      local input = { a, b, c }
      local result = table_util.find(input, b)
      assert.equal(2, result)
    end)

    it("returns nil on failure", function()
      local result = table_util.find({ "a", "b", "c", "d" }, "f")
      assert.is_nil(result)
    end)
  end)

  describe("map", function()
    it("returns values passed through callback", function()
      local input = { 1, 2, 3 }
      local result = table_util.map(input, function(i) return i * 2 end)

      assert.are_same({ 2, 4, 6 }, result)
    end)
  end)
end)
