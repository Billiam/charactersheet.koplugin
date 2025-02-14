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
  ceil = math.ceil,
  clamp = function(value, min, max) return math.max(min, math.min(max, value)) end,
  cos = math.cos,
  floor = math.floor,
  lerp = function(min, max, percent) return percent * (max - min) + min end,
  mod = math.fmod,
  pow = function(base, exp) return base ^ exp end,
  rnd = math.random,
  round = function(val) return math.floor(val + 0.5) end,
  roundeven = function(val) return math.fmod(val, 1) == 0 and val or math.floor((val + 1) / 2) * 2 end,
  roundodd = function(val) return math.fmod(val, 1) == 0 and val or math.floor((val + 2) / 2) * 2 - 1 end,
  roundfromzero = function(val) return val > 0 and math.ceil(val) or math.floor(val) end,
  roundtozero = function(val) return val > 0 and math.floor(val) or math.ceil(val) end,
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
