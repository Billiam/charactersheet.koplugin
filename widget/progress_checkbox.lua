local Button = require("ui/widget/button")
local Device = require("device")
local _ = require("gettext")
local TopContainer = require("ui/widget/container/topcontainer")

-- TODO custom icons for check states
local TICKS = {
  [0] = "",
  "‒",
  "🞣",
  "✻",
  "❊",
}

local ProgressCheckbox = TopContainer:extend{
  value = 0,
  width = 30,
  height = 24,
  callback = nil,
  margin = nil
}

function ProgressCheckbox:getSize()
  return {w = self.width, h = self.height }
end

function ProgressCheckbox:update()
  self.button:setText(self.button:text_func(), self.button.width)
  self.button:refresh()
end

function ProgressCheckbox:increment()
  self.value = self.value < 4 and (self.value + 1) or 0
  self:update()
end

function ProgressCheckbox:init()
  local callback = self.callback or function() self:increment() end

  self.button = Button:new {
    width = 30,
    height = 21,
    padding = 0,
    text_font_size = 24,
    margin = self.margin,
    bordersize = 1,
    text_func = function()
      return TICKS[self.value]
    end,
    callback = callback
  }

  self[1] = self.button
end

return ProgressCheckbox
