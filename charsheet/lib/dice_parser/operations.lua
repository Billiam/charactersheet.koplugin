local mathOperations = {
  ["+"] = function(a, b) return a + b end,
  ["-"] = function(a, b) return a - b end,
  ["*"] = function(a, b) return a * b end,
  ["/"] = function(a, b) return a / b end,
  ["^"] = function(a, b) return a ^ b end,
}
local equalityOperations = {
  [">"] = function(a, b) return a > b end,
  [">="] = function(a, b) return a >= b end,
  ["<"] = function(a, b) return a < b end,
  ["<="] = function(a, b) return a <= b end,
  ["="] = function(a, b) return a == b end,
}
local methods = {
  abs = math.abs,
  acos = math.acos,
  asin = math.asin,
  atan = math.atan,
  atan2 = math.atan,
  ceil = math.ceil,
  cos = math.cos,
  floor = math.floor,
  round = function(val) return math.floor(val + 0.5) end,
  sign = function(val) return (val > 0 and 1) or (val == 0 and 0) or -1 end,
  sin = math.sin,
  sqrt = math.sqrt,
  tan = math.tan
}
return {
  math = mathOperations,
  equality = equalityOperations,
  methods = methods
}
