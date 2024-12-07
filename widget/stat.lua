local Blitbuffer = require("ffi/blitbuffer")
local Button = require("ui/widget/button")
local Device = require("device")
local FocusManager = require("ui/widget/focusmanager")
local LineWidget = require("ui/widget/linewidget")
local Size = require("ui/size")
local VerticalGroup = require("ui/widget/verticalgroup")
local FrameContainer = require("ui/widget/container/framecontainer")
local TextWidget = require("ui/widget/textwidget")
local UIManager = require("ui/uimanager")
local SpinWidget = require("ui/widget/spinwidget")
local _ = require("gettext")

local Font = require("ui/font")
local Geom = require("ui/geometry")
local Screen = Device.screen

local Stat =  FocusManager:extend{
  width = Screen:scaleBySize(50),

  label = nil,
  value = nil,
  min = nil,
  max = nil,

  has_secondary_value = false,
  secondary_label = nil, --displayed when editing
  secondary_value = nil,
  secondary_min = nil,
  secondary_max = nil,

  label_font_size = 14
}
local function show_spinner(button, value, min, max, label, callback)
  local spinner = SpinWidget:new{
    value = value,
    value_min = min,
    value_max = max,
    value_step = 1,
    ok_text = _("Save"),
    title_text = _("Set " .. label),
    callback = function(spin)
      button:setText(spin.value, button.width)
      button:refresh()
      callback(spin.value)
    end
  }

  UIManager:show(spinner)
end

function Stat:init()
  self.stat_button = Button:new{
    text = self.value,
    width = self.width - 4,
    bordersize = 0,
    callback = function()
      show_spinner(self.stat_button, self.value, self.min, self.max, self.label,function(value)
        self.value = value
      end)
    end
  }

  local divider
  if self.has_secondary_value then
    divider = LineWidget:new{
        dimen = Geom:new {
          h = Size.border.thin,
          w = self.width - Size.border.thin * 2,
        },
      }
    self.secondary_button =  Button:new {
      text = self.secondary_value,
      bordersize = 0,
      radius = 0,
      text_font_size = 14,
      height = 10,
      padding = 8,
      width = self.width - 4,
      callback = function()
        show_spinner(self.secondary_button, self.secondary_value, self.secondary_min, self.secondary_max, self.secondary_label or (self.label .. " (secondary)"),function(value)
          self.value = value
        end)
      end
    }
  end

  local block = VerticalGroup:new{
    TextWidget:new{
      face = Font:getFace("cfont", self.label_font_size),
      text = self.label,
      max_width = self.width - Screen:scaleBySize(4)
    },
    self.stat_button,
    divider,
    self.secondary_button
  }

  local frame = FrameContainer:new{
    bordersize = Size.border.thin,
    width = self.width,
    padding = 0,
    block
  }

  local h = frame[1]:getSize().h

  self[1] = frame
end

return Stat
