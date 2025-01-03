local Device = require("device")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local _ = require("gettext")
local logger = require("logger")
local HorizontalSpan = require("ui/widget/horizontalspan")
local ProgressTrack = require("widget/progress_track")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local TextWidget = require("ui/widget/textwidget")
local Font = require("ui/font")

local Flex = require("widget/flex")
local FilledCheckbox = require("widget/filled_checkbox")

local Screen = Device.screen

local LegacyTrack = ProgressTrack:extend {
  xp = 0,
  ten_marked = false,
  checkbox_size = Screen:scaleBySize(48),
  xp_size = Screen:scaleBySize(22),
}

function LegacyTrack:clear()
  self.xp = 0
  ProgressTrack.clear(self)
end

function LegacyTrack:xpButton(index, size)
  local checked = self.xp >= index

  return FilledCheckbox:new {
    width = size,
    height = size - 2,
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

function LegacyTrack:markTen()
  self.ten_marked = not self.ten_marked
  self:updateValue()
end

function LegacyTrack:init()
  self.increment_value = 1

  self.checkboxes = {}
  self.xp_boxes = {}

  self.height = self.checkbox_size + self.xp_size + Screen:scaleBySize(4)

  self.checkboxes = self:_buildCheckboxes()
  local checkbox_groups = {}

  self._available_width = self.width

  local xp_gap = Screen:scaleBySize(2)
  local xp_size = math.min(self.xp_size, (self.checkbox_size - xp_gap) / 2)

  for i = 1, 10 do
    local xp_index = (i - 1) * 2 + 1

    local xp1 = self:xpButton(xp_index, xp_size)
    local xp2 = self:xpButton(xp_index + 1, xp_size)
    self.xp_boxes[xp_index] = xp1
    self.xp_boxes[xp_index + 1] = xp2

    local xp_block = HorizontalGroup:new {
      xp1,
      HorizontalSpan:new {
        width = xp_gap
      },
      xp2,
    }

    table.insert(checkbox_groups, VerticalGroup:new {
      self.checkboxes[i],
      VerticalSpan:new {
        width = Screen:scaleBySize(4)
      },
      xp_block,
    })
  end
  local ten_marked_checkbox
  ten_marked_checkbox = FilledCheckbox:new {
    width = self.xp_size,
    height = self.xp_size - 2,
    padding = 0,
    checked = self.ten_marked,
    callback = function()
      self:markTen()
      ten_marked_checkbox:setChecked(self.ten_marked)
    end
  }

  table.insert(checkbox_groups, Flex:new {
    direction = Flex.VERTICAL,
    justify_content = Flex.SPACE_BETWEEN,
    children = {
      TextWidget:new {
        text = "10",
        face = Font:getFace("cfont", 16),
        bold = true,
      },
      ten_marked_checkbox
    }
  })

  local justify_content = Flex.CENTER
  local gap
  if self.spacing then
    gap = self.spacing
  else
    justify_content = Flex.SPACE_BETWEEN
  end

  self[1] = Flex:new {
    gap = gap,
    width = self._available_width,
    justify_content = justify_content,
    align_items = Flex.STRETCH,
    children = checkbox_groups,
  }
end

function LegacyTrack:updateXp()
  for i = 1, 20 do
    local checked = self.xp >= i
    self.xp_boxes[i]:setChecked(checked)
  end
  self:updateValue()
end

function LegacyTrack:selectXp(i)
  if self.xp == i then
    self.xp = i - 1
  else
    self.xp = i
  end

  self:updateXp()
end

function LegacyTrack:updateValue()
  self.callback(self.name, { xp = self.xp, value = self.value, ten_marked = self.ten_marked })
end

return LegacyTrack
