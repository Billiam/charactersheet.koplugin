local FrameContainer = require("ui/widget/container/framecontainer")
local TextWidget = require("ui/widget/textwidget")
local VerticalGroup = require("ui/widget/verticalgroup")
local CenterContainer = require("ui/widget/container/centercontainer")
local LeftContainer = require("ui/widget/container/leftcontainer")
local RightContainer = require("ui/widget/container/rightcontainer")

local Blitbuffer = require("ffi/blitbuffer")
local Font = require("ui/font")
local Size = require("ui/size")
local Geom = require("ui/geometry")

local Section = FrameContainer:extend {
  label = nil,
  label_position = "top",
  label_size = 16,
  label_alignment = "center",
  label_bold = false,
  label_padding = 0,
  label_radius = 0,

  radius = 0,
  bordersize = 0,
  align = "center",
  children = {},
  invert_label = false,
  -- TODO: left/right vs top/bottom padding
  inner_padding = Size.padding.default,
  margin = 0,
}

function Section:labelClass()
  if self.label_alignment == "right" then
    return RightContainer
  end
  if self.label_alignment == "left" then
    return LeftContainer
  end

  return CenterContainer
end

function Section:init()
  self.padding = 0

  self.content = FrameContainer:new {
    bordersize = 0,
    padding = self.inner_padding,
    VerticalGroup:new {
      align = "left",
      table.unpack(self.children)
    }
  }

  local text = TextWidget:new {
    text = self.label,
    fgcolor = self.invert_label and Blitbuffer.COLOR_WHITE or Blitbuffer.COLOR_BLACK,
    face = Font:getFace("cfont", self.label_size),
    bold = self.label_bold
  }

  if not self.width then
    self.width = math.max(self.content:getSize().w, text:getSize().w) + 2 * self.inner_padding + self.bordersize * 2 +
        self.margin * 2
  end

  text.max_width = self.width
  self.dimen = Geom:new {
    w = self.width,
    h = 150,
  }

  local label = FrameContainer:new {
    bordersize = 0,
    padding = 0,
    radius = self.label_radius,
    background = self.invert_label and Blitbuffer.COLOR_BLACK or Blitbuffer.COLOR_WHITE,
    self:labelClass():new {
      dimen = Geom:new {
        w = self.width - self.bordersize * 2 + self.label_padding * 2,
        h = text:getSize().h
      },
      text
    }
  }

  local outer_group = VerticalGroup:new {
    align = self.align,
    self.content,
  }

  if self.label_position == "top" then
    table.insert(outer_group, 1, label)
  else
    table.insert(outer_group, label)
  end

  self[1] = outer_group
end

return Section
