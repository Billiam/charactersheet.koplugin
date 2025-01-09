local TextWidget = require("ui/widget/textwidget")
local RenderText = require("ui/rendertext")
local Geom = require("ui/geometry")

local RotatableTextWidget = TextWidget:extend {
  rotation = 0,
}

function RotatableTextWidget:init()
  self.use_xtext = false
end

function RotatableTextWidget:getSize()
  if self.rotation == 0 then
    return TextWidget.getSize(self)
  end

  self:updateSize()
  return Geom:new {
    x = 0,
    y = 0,
    w = self.forced_height or self._height,
    h = self._length,
  }
end

function RotatableTextWidget:paintTo(bb, x, y)
  self:updateSize()
  if self._is_empty then
    return
  end

  local h = bb:getHeight()
  local w = bb:getWidth()

  if self.rotation > 0 then
    x, y = y, w - self._height - x
  else
    x, y = h - self._length - y, x
  end

  bb:rotateAbsolute(self.rotation)

  RenderText:renderUtf8Text(bb, x, y + self._baseline_h, self.face, self._text_to_draw,
    true, self.bold, self.fgcolor, self._length)
  bb:rotateAbsolute(0)
end

return RotatableTextWidget
