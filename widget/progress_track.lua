local Device = require("device")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local _ = require("gettext")
local logger = require("logger")
local TopContainer = require("ui/widget/container/topcontainer")

local ProgressCheckbox = require("widget/progress_checkbox")

local ProgressTrack = TopContainer:extend{
  value = 0,
  width = 400,
  height = 50,
  increment_value = 1,
}

function ProgressTrack:getSize()
  return {w = self.width, h = self.height }
end

function ProgressTrack:decrement()
  self.value = math.max(0,self.value - self.increment_value)
end

function ProgressTrack:increment()
  self.value = math.min(40,self.value + self.increment_value)
end

function ProgressTrack:clear()
  self.value = 0
  self:update()
end

function ProgressTrack:update()
  local total = self.value
  for i=1,10 do
    local value = math.min(4, total)
    total = total - value
    if self.checkboxes[i].value ~= value then
      self.checkboxes[i].value = value
      self.checkboxes[i]:update()
    end
  end
end

function ProgressTrack:init()
  self.checkboxes = {}

  local set_value = function(i)
    local start_value = (i - 1) * 4 + self.checkboxes[i].value
    local next_value = (math.floor(start_value / self.increment_value) + 1) * self.increment_value

    if self.checkboxes[i].value > 0 and next_value > i * 4 then
      next_value = math.floor((i - 1) * 4 / self.increment_value) * self.increment_value
    end

    self.value = next_value
    self:update()
  end

  local total = self.value

  for i=1,10 do
    local value = math.min(4, total)
    total = total - value

    self.checkboxes[i] = ProgressCheckbox:new{
      value = value,
      margin = 3,
      callback = function()
        set_value(i)
      end
    }
  end

  self[1] = HorizontalGroup:new{
    table.unpack(self.checkboxes)
  }
end

return ProgressTrack
