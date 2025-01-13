local Device = require("device")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local _ = require("gettext")
local logger = require("logger")
local HorizontalSpan = require("ui/widget/horizontalspan")
local ProgressTrack = require("charsheet/widget/ironsworn/progress_track")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local TextWidget = require("ui/widget/textwidget")
local Font = require("ui/font")

local _t = require("charsheet/lib/table_util")
local FlexContainer = require("charsheet/widget/flex_container")
local FilledCheckbox = require("charsheet/widget/filled_checkbox")

local Screen = Device.screen

local LegacyTrack = ProgressTrack:extend {
  checkbox_size = Screen:scaleBySize(44),
  xp_size = Screen:scaleBySize(21),
}

function LegacyTrack:clear()
  self.value.xp = 0
  ProgressTrack.clear(self)
end

function LegacyTrack:xpButton(index, size)
  local checked = self.value.xp >= index

  return FilledCheckbox:new {
    size = size,
    padding = 0,
    checked = checked,
    callback = function()
      self:xpCallback(index)
    end
  }
end

function LegacyTrack:xpCallback(index)
  if self.value.xp >= index then
    self.value.xp = index - 1
  else
    self.value.xp = index
  end
  self:updateXp()
  self:onUpdateValue()
end

function LegacyTrack:markTen(value)
  self.value.ten_marked = value
  self.ten_marked_checkbox:setChecked(self.value.ten_marked)
end

function LegacyTrack:init()
  local default = {
    value = 0,
    xp = 0,
    ten_marked = false,
  }
  if self.value then
    for k, v in pairs(default) do
      if self.value[k] == nil then
        self.value[k] = v
      end
    end
  else
    self.value = default
  end
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
  self.ten_marked_checkbox = FilledCheckbox:new {
    size = self.xp_size,
    padding = 0,
    checked = self.value.ten_marked,
    callback = function()
      self:markTen(not self.value.ten_marked)
      self:onUpdateValue()
    end
  }

  table.insert(checkbox_groups, FlexContainer:new {
    direction = FlexContainer.VERTICAL,
    justify_content = FlexContainer.SPACE_BETWEEN,
    children = {
      TextWidget:new {
        text = "10",
        face = Font:getFace("cfont", 16),
        bold = true,
      },
      self.ten_marked_checkbox
    }
  })

  local justify_content = FlexContainer.CENTER
  local gap
  if self.spacing then
    gap = self.spacing
  else
    justify_content = FlexContainer.SPACE_BETWEEN
  end

  self[1] = FlexContainer:new {
    gap = gap,
    width = self._available_width,
    justify_content = justify_content,
    align_items = FlexContainer.STRETCH,
    children = checkbox_groups,
  }
end

function LegacyTrack:updateXp()
  for i = 1, 20 do
    local checked = self.value.xp >= i
    self.xp_boxes[i]:setChecked(checked)
  end
end

function LegacyTrack:onUpdateValue()
  self.callback(self.name, self.value)
end

function LegacyTrack:updateValue(value)
  local previous_value = self.value
  self.value = _t.clone(value)
  local changed = false
  if self.value.xp ~= previous_value.xp then
    changed = true
    self:updateXp()
  end
  if self.value.ten_marked ~= previous_value.ten_marked then
    changed = true
    self:markTen(value.ten_marked)
  end
  if changed or self.value.value ~= previous_value.value then
    self:update()
  end
end

function LegacyTrack:getValue()
  return self.value
end

return LegacyTrack
