local Blitbuffer = require("ffi/blitbuffer")
local WidgetContainer = require("ui/widget/container/widgetcontainer")

local ShadowContainer = WidgetContainer:extend {
  shadow_color = Blitbuffer.COLOR_GRAY,
  shadow_x = 5,
  shadow_y = 5,
  stripe_width = 0,
  margin = 0,
  radius = 0,
}

function ShadowContainer:paintTo(bb, x, y)
  local child_size = self[1]:getSize()
  local x_pos = x + self.shadow_x + self.margin
  local y_pos = y + self.shadow_y + self.margin
  local w = child_size.w - self.margin * 2
  local h = child_size.h - self.margin * 2

  if self.stripe_width > 0 then
    bb:hatchRect(
      x_pos,
      y_pos,
      w,
      h,
      self.stripe_width,
      self.shadow_color
    )
  else
    bb:paintRoundedRect(
      x_pos,
      y_pos,
      w,
      h,
      self.shadow_color,
      self.radius
    )
  end
  self[1]:paintTo(bb, x, y)
end

return ShadowContainer
