local Blitbuffer = require("ffi/blitbuffer")

local Device = require("device")
local logger = require("logger")
local _ = require("gettext")

local Font = require("ui/font")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local Size = require("ui/size")
local UIManager = require("ui/uimanager")

local Button = require("ui/widget/button")
local LineWidget = require("ui/widget/linewidget")
local SpinWidget = require("ui/widget/spinwidget")
local TextWidget = require("ui/widget/textwidget")
local VerticalGroup = require("ui/widget/verticalgroup")

local CenterContainer = require("ui/widget/container/centercontainer")
local FrameContainer = require("ui/widget/container/framecontainer")
local InputContainer = require("ui/widget/container/inputcontainer")

local Screen = Device.screen

local Stat = InputContainer:extend {
  width = Screen:scaleBySize(50),

  label = nil,
  value = nil,
  min = nil,
  max = nil,
  radius = 5,

  has_secondary_value = false,
  secondary_label = nil, --displayed when editing
  secondary_value = nil,
  secondary_min = nil,
  secondary_max = nil,

  value_font_size = 18,
  label_font_size = 14,

  invert_label = false,
  margin = 2,
  name = nil,
  callback = nil,
  hold_callback = nil,
}

function Stat:init()
  self.value = self.value or { value = 0 }

  if self.min then
    self.value.value = math.max(self.min, self.value.value)
  end
  if self.max then
    self.value.value = math.min(self.max, self.value.value)
  end

  self.value_text = TextWidget:new {
    text = self.value.value,
    face = Font:getFace("cfont", self.value_font_size),
    bold = true,
  }
  local divider
  if self.has_secondary_value then
    self.value.secondary = self.value.secondary or 0
    if self.secondary_min then
      self.value.secondary = math.min(self.secondary_min, self.value.secondary)
    end
    if self.secondary_max then
      self.value.secondary = math.min(self.secondary_max, self.value.secondary)
    end

    divider = LineWidget:new {
      dimen = Geom:new {
        h = Size.border.thin,
        w = self.width - Size.border.thin * 2,
      },
    }
    self.secondary_button = Button:new {
      text = self.secondary_value,
      bordersize = 0,
      radius = 0,
      text_font_size = 14,
      height = 10,
      padding = 8,
      width = self.width - 4,
      callback = function()
        self:showSpinner(
          false,
          self.value.secondary,
          self.secondary_min,
          self.secondary_max,
          self.secondary_label or (self.label .. " (secondary)"),
          function(value)
            self.value.secondary = value
          end)
      end
    }
  end

  local label = TextWidget:new {
    face = Font:getFace("cfont", self.label_font_size),
    text = self.label,
    max_width = self.width - Screen:scaleBySize(4),
    fgcolor = self.invert_label and Blitbuffer.COLOR_WHITE or Blitbuffer.COLOR_BLACK
  }

  self.value_box = CenterContainer:new {
    show_parent = self,
    dimen = Geom:new {
      w = self.width - 4,
      h = self.value_text:getSize().h
    },
    self.value_text,
  }

  local block = FrameContainer:new {
    background = Blitbuffer.COLOR_WHITE,
    bordersize = Size.border.thin,
    margin = 0,
    padding = 0,
    radius = self.radius,
    VerticalGroup:new {
      align = "left",
      FrameContainer:new {
        padding = 0,
        margin = 0,
        bordersize = 0,
        background = self.invert_label and Blitbuffer.COLOR_BLACK,
        width = self.width - 4,

        radius = self.radius,
        CenterContainer:new {
          dimen = Geom:new {
            w = self.width - Screen:scaleBySize(4),
            h = label:getSize().h
          },
          label
        }
      },
      self.value_box,
      divider,
      self.secondary_button
    }
  }

  local frame = FrameContainer:new {
    bordersize = 0,
    width = self.width,
    margin = self.margin,
    padding = 0,
    block
  }

  self[1] = frame
  self.dimen = frame:getSize()

  self.ges_events = {
    Tap = {
      GestureRange:new {
        ges = "tap",
        range = self.dimen
      }
    },
    Swipe = {
      GestureRange:new {
        ges = "swipe",
        range = self.dimen
      }
    }
  }
  if self.hold_callback then
    self.ges_events.Hold = {
      GestureRange:new {
        ges = "hold",
        range = self.dimen
      }
    }
  end
end

function Stat:showSpinner(primary_label, value, min, max, label, callback)
  local spinner = SpinWidget:new {
    value = value,
    value_min = min,
    value_max = max,
    value_step = 1,
    ok_text = _("Save"),
    title_text = _("Set " .. label),

    callback = function(spin)
      if primary_label then
        self:setValue(spin.value)
        self:refresh()
      else
        self:setSecondaryValue(spin.value)
        self.secondary_button:refresh()
      end
      callback(spin.value)
    end
  }

  UIManager:show(spinner)
end

function Stat:increment()
  self:deviate(1)
end

function Stat:decrement()
  self:deviate(-1)
end

function Stat:deviate(amount)
  local original_value = self.value.value
  self.value.value = self.value.value + amount
  if self.min then
    self.value.value = math.max(self.min, self.value.value)
  end
  if self.max then
    self.value.value = math.min(self.max, self.value.value)
  end

  if self.value.value ~= original_value then
    self.value_text:setText(self.value.value)
    self:refresh()
  end
end

function Stat:refresh()
  UIManager:setDirty(self.show_parent, "partial", self.dimen)
  self.callback(self.name, self.value)
end

function Stat:onSwipe(_, ges)
  local direction = ges.direction
  if direction == "north" then
    self:increment()
    return true
  elseif direction == "south" then
    self:decrement()
    return true
  end
end

function Stat:onTap()
  self:showSpinner(true, self.value.value, self.min, self.max, self.label, function(value)
    self.value.value = value
    self.callback(self.name, self.value)
  end)
end

function Stat:onHold()
  self.hold_callback(self)
end

function Stat:setValue(value)
  self.value.value = value
  self.value_text:setText(value)
end

function Stat:setSecondaryValue(value)
  self.value.secondary = value
  self.secondary_button:setText(value)
end

function Stat:updateValue(value)
  local changed = value.value ~= self.value.value or
      (self.has_secondary_value and self.value.secondary ~= value.secondary)
  logger.warn("changed", changed, value.value, self.value.value)

  self:setValue(value.value)
  if self.has_secondary_value then
    self:setSecondaryValue(value.secondary)
  end

  if changed then
    self:refresh()
  end
end

return Stat
