local Blitbuffer = require("ffi/blitbuffer")
local Button = require("ui/widget/button")

local FilledCheckbox = Button:extend{
  checked = false,
  padding = 0,
  bordersize = 1
}

function FilledCheckbox:init()
  self.text = ""

  self.background = self.checked and Blitbuffer.COLOR_BLACK or Blitbuffer.COLOR_WHITE
  Button.init(self)
end

function FilledCheckbox:setChecked(checked)
  if checked ~= self.checked then
    self.checked = checked
    self.frame.background = checked and Blitbuffer.COLOR_BLACK or Blitbuffer.COLOR_WHITE
    self:refresh()
  end
end

return FilledCheckbox
