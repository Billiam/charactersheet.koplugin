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

return {
  math = mathOperations,
  equality = equalityOperations,
}
