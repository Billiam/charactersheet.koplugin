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

  align = "center",
  items = {},
  invert_label = false,
  inner_padding = Size.padding.default,
  margin = 2,
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
      table.unpack(self.items)
    }
  }

  local text = TextWidget:new {
    text = self.label,
    fgcolor = self.invert_label and Blitbuffer.COLOR_WHITE or Blitbuffer.COLOR_BLACK,
    face = Font:getFace("cfont", self.label_size),
    bold = self.label_bold
  }

  local width = self.width
  if not width then
    width = math.max(self.content:getSize().w, text:getSize().w + self.inner_padding * 2)
  end

  local label = FrameContainer:new {
    bordersize = 0,
    width = width,
    padding = 0,
    margin = 0,
    background = self.invert_label and Blitbuffer.COLOR_BLACK or Blitbuffer.COLOR_WHITE,
    self:labelClass():new {
      dimen = Geom:new {
        w = width,
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
