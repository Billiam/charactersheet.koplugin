local Blitbuffer = require("ffi/blitbuffer")
local FrameContainer = require("ui/widget/container/framecontainer")

local Geom = require("ui/geometry")

local ShadowContainer = FrameContainer:extend {
  background = Blitbuffer.COLOR_GRAY,
  shadow_x = 5,
  shadow_y = 5,
  stripe_width = 0,
  padding = 0,
  radius = 0,
}

function ShadowContainer:paintTo(bb, x, y)
  local shadow_size = self:getSize()
  local child_size = self[1]:getSize()

  local shadow_x = x + self.shadow_x + self.margin + self._padding_left
  local shadow_y = y + self.shadow_y + self.margin + self._padding_top

  if not self.dimen then
    self.dimen = Geom:new {
      x = x,
      y = y,
      w = shadow_size.w,
      h = shadow_size.h,
    }
  else
    self.dimen.x = x
    self.dimen.y = y
  end

  if self.stripe_width > 0 then
    bb:hatchRect(
      shadow_x,
      shadow_y,
      child_size.w,
      child_size.h,
      self.stripe_width,
      self.background
    )
  else
    bb:paintRoundedRect(
      shadow_x,
      shadow_y,
      child_size.w,
      child_size.h,
      self.background,
      self.radius
    )
  end
  self[1]:paintTo(
    bb,
    x + self.margin + self._padding_left,
    y + self.margin + self._padding_top
  )
end

return ShadowContainer
