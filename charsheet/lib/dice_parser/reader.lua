local Reader = {}
Reader.__index = Reader

function Reader:new(str)
  local o = {}
  o.pos = 1
  o.len = #str
  o.str = str

  return setmetatable(o, self)
end

function Reader:read(n)
  n = n or 1

  local str = self:peek(n)
  self.pos = self.pos + n

  return str
end

function Reader:peek(n)
  n = n or 1
  return self.str:sub(self.pos, self.pos + n - 1)
end

function Reader:cur()
  return self.str:sub(self.pos, self.pos)
end

function Reader:skipWhitespace()
  self:match("^%s+")
end

function Reader:eof()
  return self.pos >= self.len
end

function Reader:match(pattern, consume)
  consume = consume == nil and true or consume

  local start, finish = self.str:sub(self.pos):find(pattern)
  if start then
    local match = self.str:sub(self.pos + start - 1, self.pos + finish - 1)

    if consume then
      self.pos = self.pos + finish
    end

    return match
  end
end

return Reader
