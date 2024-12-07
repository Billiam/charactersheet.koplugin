local Device = require("device")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local _ = require("gettext")
local logger = require("logger")
local HorizontalSpan = require("ui/widget/horizontalspan")
local ProgressTrack = require("widget/progress_track")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local FilledCheckbox = require("widget/filled_checkbox")

local Screen = Device.screen

local LegacyTrack = ProgressTrack:extend{
  xp = 0,
  checkbox_size = Screen:scaleBySize(36),
  xp_size = Screen:scaleBySize(17),
}

function LegacyTrack:clear()
  self.xp = 0
  ProgressTrack.clear(self)
end

function LegacyTrack:xpButton(index)
  local checked = self.xp >= index
  return FilledCheckbox:new{
    width = self.xp_size,
    height = self.xp_size - 2,
    padding = 0,
    checked = checked,
    callback = function()
      self:xpCallback(index)
    end
  }
end

function LegacyTrack:xpCallback(index)
  if self.xp >= index then
    self.xp = index - 1
  else
    self.xp = index
  end
  self:updateXp()
end

function LegacyTrack:init()
  self.increment_value = 4

  self.checkboxes = {}
  self.xp_boxes = {}

  self.height = self.checkbox_size + self.xp_size + Screen:scaleBySize(4)

  self.checkboxes = self:buildCheckboxes()
  local checkbox_groups = {}

  for i=1,10 do
    local xp_index = ((i - 1) * 2) + 1

    local xp1 = self:xpButton(xp_index)
    local xp2 = self:xpButton(xp_index + 1)
    self.xp_boxes[xp_index] = xp1
    self.xp_boxes[xp_index + 1] = xp2

    local xp_block = HorizontalGroup:new {
      xp1,
      HorizontalSpan:new {
        width = Screen:scaleBySize(2)
      },
      xp2,
    }

    table.insert(checkbox_groups, VerticalGroup:new{
      self.checkboxes[i],
      VerticalSpan:new {
        width = Screen:scaleBySize(4)
      },
      xp_block,
    })

    table.insert(checkbox_groups, HorizontalSpan:new { width = 4 })
  end

  self[1] = HorizontalGroup:new{
    table.unpack(checkbox_groups)
  }
end

function LegacyTrack:updateXp()
 for i=1,20 do
    local checked = self.xp >= i
    self.xp_boxes[i]:setChecked(checked)
  end
end

function LegacyTrack:selectXp(i)
  if self.xp == i then
    self.xp = i - 1
  else
    self.xp = i
  end
  self:updateXp()
end
return LegacyTrack
