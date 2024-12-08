local Blitbuffer = require("ffi/blitbuffer")
local Button = require("ui/widget/button")
local Device = require("device")
local FocusManager = require("ui/widget/focusmanager")
local LineWidget = require("ui/widget/linewidget")
local Size = require("ui/size")
local VerticalGroup = require("ui/widget/verticalgroup")
local FrameContainer = require("ui/widget/container/framecontainer")
local CenterContainer = require("ui/widget/container/centercontainer")

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

  label_font_size = 14,
  shadow_color = Blitbuffer.COLOR_GRAY,
  shadow_x = 5,
  shadow_y = 5,

  invert_label = false,
  margin = 2,
  name = nil,
  callback = nil,
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
        self.callback(self.name, self.value)
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

  local label = TextWidget:new{
    face = Font:getFace("cfont", self.label_font_size),
    text = self.label,
    max_width = self.width - Screen:scaleBySize(4),
    fgcolor = self.invert_label and Blitbuffer.COLOR_WHITE or Blitbuffer.COLOR_BLACK
  }

  local block = FrameContainer:new{
    background = Blitbuffer.COLOR_WHITE,
    bordersize = Size.border.thin,
    margin = 0,
    padding = 0,
    VerticalGroup:new{
      align = "left",
      FrameContainer:new{
        padding = 0,
        margin = 0,
        bordersize = 0,
        background = self.invert_label and Blitbuffer.COLOR_BLACK,
        width = self.width - 4,
        CenterContainer:new{
          dimen = Geom:new{
            w = self.width - Screen:scaleBySize(4),
            h = label:getSize().h
          },
          label
        }
      },
      self.stat_button,
      divider,
      self.secondary_button
    }
  }

  local frame = FrameContainer:new{
    bordersize = 0,
    width = self.width,
    margin = self.margin,
    padding = 0,
    block
  }

  self[1] = frame
end

function Stat:paintTo(bb, x, y)

  if self.shadow_color then
    local my_size = self:getSize()
    bb:hatchRect(
      x + self.shadow_x + self.margin,
      y + self.shadow_y + self.margin,
      my_size.w - self.margin * 2,
      my_size.h - self.margin * 2,
      2,
      self.shadow_color
    )
  end

  self[1]:paintTo(bb, x, y)
end

return Stat
