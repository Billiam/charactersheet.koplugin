local Device = require("device")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local _ = require("gettext")
local logger = require("logger")
local TopContainer = require("ui/widget/container/topcontainer")
local HorizontalSpan = require("ui/widget/horizontalspan")
local ProgressCheckbox = require("widget/progress_checkbox")

local Screen = Device.screen

local ProgressTrack = TopContainer:extend{
  value = 0,
  width = 300,
  checkbox_size = Screen:scaleBySize(25),
  increment_value = 1,
  path = nil
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
  self.height = self.height or self.checkbox_size + 5

  self.checkboxes = self:buildCheckboxes()
  local group_content = {}
  for i=1,10 do
    table.insert(group_content, self.checkboxes[i])
    table.insert(group_content, HorizontalSpan:new { width = 4 })
  end
  self[1] = HorizontalGroup:new{
    table.unpack(group_content)
  }
end

function ProgressTrack:buildCheckboxes()
  local total = self.value
  local checkboxes = {}
  for i=1,10 do
    local value = math.min(4, total)
    total = total - value

    checkboxes[i] = ProgressCheckbox:new{
      value = value,
      path = self.path,
      width = self.checkbox_size,
      height = self.checkbox_size,
      callback = function()
        self:selectCheckbox(i)
      end
    }
  end

  return checkboxes
end

function ProgressTrack:selectCheckbox(i)
  local start_value = (i - 1) * 4 + self.checkboxes[i].value
  local next_value = (math.floor(start_value / self.increment_value) + 1) * self.increment_value

  if self.checkboxes[i].value > 0 and next_value > i * 4 then
    next_value = math.floor((i - 1) * 4 / self.increment_value) * self.increment_value
  end

  self.value = next_value
  self:update()
end

return ProgressTrack
