local say = require("say")
local util = require('luassert.util')
local assert = require('luassert.assert')

assert:set_parameter("TableFormatLevel", -1)

local deep_includes
deep_includes = function(ta, tb, cycles)
  cycles = cycles or {}

  for k, v in pairs(ta) do
    local v_b = tb[k]

    if v ~= v_b then
      local type_a = type(v)
      local type_b = type(v_b)
      if type_a ~= type_b then
        return false, { k }
      end
      if v_b == nil then
        return false, { k }
      end

      if type_a == "table" and type_b == "table" then
        if not cycles[v] then
          cycles[v] = true
          local result, crumbs = deep_includes(v, tb[k], cycles)
          if not result then
            crumbs = crumbs or {}
            table.insert(crumbs, k)
            return false, crumbs
          end
        end
      else
        return false, { k }
      end
    end
  end

  return true
end

local function includes(state, arguments, level)
  level = (level or 1) + 1

  local argcnt = arguments.n
  assert(argcnt > 1, say("assertion.internal.argtolittle", { "includes", 2, tostring(argcnt) }), level)

  if type(arguments[1]) == 'table' and type(arguments[2]) == 'table' then
    local result, crumbs = deep_includes(arguments[1], arguments[2])

    -- switch arguments for proper output message
    util.tinsert(arguments, 1, util.tremove(arguments, 2))
    arguments.fmtargs = arguments.fmtargs or {}
    arguments.fmtargs[1] = { crumbs = crumbs }
    arguments.fmtargs[2] = { crumbs = crumbs }

    state.failure_message = arguments[3]
    return result
  end
  local result = arguments[1] == arguments[2]
  util.tinsert(arguments, 1, util.tremove(arguments, 2))
  state.failure_message = arguments[3]
  return result
end


say:set("assertion.includes.positive", "Objects missing required values.\nPassed in:\n%s\nExpected:\n%s")
say:set("assertion.includes.negative",
  "Expected to not include all required values.\nPassed in:\n%s\nDid not expect:\n%s")
assert:register("assertion", "includes", includes, "assertion.includes.positive", "assertion.includes.negative")
