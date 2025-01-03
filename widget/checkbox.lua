local logger = require("logger")

local Blitbuffer = require("ffi/blitbuffer")

local Font = require("ui/font")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local UIManager = require("ui/uimanager")

local TextWidget = require("ui/widget/textwidget")

local HorizontalGroup = require("ui/widget/horizontalgroup")
local HorizontalSpan = require("ui/widget/horizontalspan")
local RectSpan = require("ui/widget/rectspan")

local FrameContainer = require("ui/widget/container/framecontainer")
local InputContainer = require("ui/widget/container/inputcontainer")

local Checkbox = InputContainer:extend {
  font_size = 16,
  name = nil,
  text = nil,
  checked = false,
  enabled = true,

  size = 16,
}

function Checkbox:init()
  -- TODO: circle widget of some kind for radio display
  self.checkmark = FrameContainer:new {
    padding = 0,
    margin = 0,
    width = self.size,
    height = self.size,
    bordersize = 1,
    radius = 0,
    background = self.checked and Blitbuffer.COLOR_BLACK or Blitbuffer.COLOR_WHITE,

    RectSpan:new {
      width = self.size - 2,
      height = self.size - 2,
    }
  }
  local elements = {
    self.checkmark
  }
  if self.text then
    elements[2] = HorizontalSpan:new { width = self.font_size / 2 }

    elements[3] = TextWidget:new {
      face = Font:getFace("cfont", self.font_size),
      text = self.text
    }
  end

  local h_group = HorizontalGroup:new {
    table.unpack(elements)
  }
  self[1] = h_group

  local size = h_group:getSize()

  self.dimen = Geom:new {
    w = size.w,
    h = size.h
  }
  self.ges_events = {
    Tap = {
      GestureRange:new {
        ges = "tap",
        range = self.dimen
      }
    }
  }
end

function Checkbox:onTap()
  if not self.enabled then
    return
  end

  self.checked = not self.checked
  if self.callback then
    self.callback(self.name, self.checked)
  end
  self.checkmark.background = self.checked and Blitbuffer.COLOR_BLACK or Blitbuffer.COLOR_WHITE

  UIManager:setDirty(self.show_parent, "ui", self[1].dimen)
end

return Checkbox
