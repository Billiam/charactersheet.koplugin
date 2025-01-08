local HorizontalGroup = require("ui/widget/horizontalgroup")
local LineWidget = require("ui/widget/linewidget")
local TextWidget = require("ui/widget/textwidget")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local Font = require("ui/font")
local Device = require("device")
local Geom = require("ui/geometry")
local Size = require("ui/size")
local HorizontalSpan = require("ui/widget/horizontalspan")

local Screen = Device.screen

local Divider = WidgetContainer:extend{
  label = nil,
  font_size = 16,
  bold = true,
  width = nil,
  thick = Size.line.thick
}

function Divider:init()
  if self.label then
    local label = TextWidget:new{
      text = self.label,
      face = Font:getFace("cfont", self.font_size),
      bold = self.bold
    }

    local text_width = label:getSize().w
    local spacer_width = Screen:scaleBySize(6)
    local divider_width = (self.width - text_width - spacer_width * 2)/2

    self[1] = HorizontalGroup:new{
      LineWidget:new{
        dimen = Geom:new{
          w = divider_width,
          h = self.thick
        }
      },
      HorizontalSpan:new{
        width = spacer_width
      },
      label,
      HorizontalSpan:new{
        width = spacer_width
      },
      LineWidget:new{
        dimen = Geom:new{
          w = divider_width,
          h = self.thick
        }
      },
    }
  else
    self[1] = LineWidget:new{
      dimen = Geom:new{
        w = self.width,
        h = self.thick
      }
    }
  end
end

return Divider
