local Blitbuffer = require("ffi/blitbuffer")
local FrameContainer = require("ui/widget/container/framecontainer")
local RectSpan = require("ui/widget/rectspan")
local UIManager = require("ui/uimanager")
local InputContainer = require("ui/widget/container/inputcontainer")
local GestureRange = require("ui/gesturerange")

local FilledCheckbox = InputContainer:extend {
  checked = false,
  enabled = true,
  bordersize = 1,
  size = 10,
  callback = nil,
}

function FilledCheckbox:init()
  self.checked = self.value
  self[1] = FrameContainer:new {
    bordersize = self.bordersize,
    width = self.size,
    height = self.size,
    padding = 0,
    background = self.checked and Blitbuffer.COLOR_BLACK or Blitbuffer.COLOR_WHITE,
    RectSpan:new {
      width = self.size - self.bordersize * 2,
      height = self.size - self.bordersize * 2,
    }
  }

  self.dimen = self[1]:getSize()

  self.ges_events = {
    Tap = {
      GestureRange:new {
        ges = "tap",
        range = self.dimen
      }
    }
  }
end

function FilledCheckbox:setChecked(checked)
  if checked == self.checked then
    return
  end

  self.checked = checked
  self[1].background = checked and Blitbuffer.COLOR_BLACK or Blitbuffer.COLOR_WHITE

  UIManager:widgetRepaint(self[1], self[1].dimen.x, self.dimen.y)
  UIManager:setDirty(nil, "ui", self[1].dimen)
end

function FilledCheckbox:onTap()
  if not self.enabled then
    return
  end

  self:setChecked(not self.checked)


  if self.callback then
    self.callback(self.name, self.checked)
  end
end

function FilledCheckbox:updateValue(value)
  self:setChecked(value)
end

function FilledCheckbox:getValue()
  return self.checked
end

return FilledCheckbox
