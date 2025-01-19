local P = {}
local P_meta = {
  __index = P,
  __call = function(_, name, callback)
    return function(...)
      local parser = callback(...)

      return function(str)
        local result = parser(str)
        if result then
          result.parser = name
        end
        return result
      end
    end
  end
}
setmetatable(P, P_meta)

function P.err(message)
  return {
    err = message
  }
end

return P
