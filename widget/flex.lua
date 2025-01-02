local HorizontalGroup = require("ui/widget/horizontalgroup")
local HorizontalSpan = require("ui/widget/horizontalspan")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")

local BottomContainer = require("ui/widget/container/bottomcontainer")
local CenterContainer = require("ui/widget/container/centercontainer")
local LeftContainer = require("ui/widget/container/leftcontainer")
local RightContainer = require("ui/widget/container/rightcontainer")
local TopContainer = require("ui/widget/container/topcontainer")
local WidgetContainer = require("ui/widget/container/widgetcontainer")


local SPACE_BETWEEN = "space-between"
local FLEX_START = "flex-start"
local FLEX_END = "flex-end"
local STRETCH = "stretch"
local HORIZONTAL = "horizontal"
local VERTICAL = "vertical"

local Flex = WidgetContainer:extend {
  direction = HORIZONTAL,
  children = nil,
  align_items = FLEX_START,
  justify_content = FLEX_START,

  width = nil,
  height = nil,
  gap = nil,
}

local horizontal = {
  container_class = HorizontalGroup,
  span_class = HorizontalSpan,
  flex_start_class = LeftContainer,
  flex_end_class = RightContainer,

  align_dimension = "h",
  align_long = "height",
  flex_dimension = "w",
  align_start = "top",
  align_end = "bottom",
}

local vertical = {
  container_class = VerticalGroup,
  span_class = VerticalSpan,
  flex_start_class = TopContainer,
  flex_end_class = BottomContainer,

  align_dimension = "w",
  align_long = "width",
  flex_dimension = "h",
  align_start = "left",
  align_end = "right",
}

function Flex:init()
  local container_align
  local children_count = #self.children

  local size = {
    w = self.width,
    h = self.height
  }
  local dir = self.direction == HORIZONTAL and horizontal or vertical

  if self.align_items == STRETCH or self.align_items == FLEX_START then
    container_align = dir.align_start
  elseif self.align_items == FLEX_END then
    container_align = dir.align_end
  end

  local max_align = 0
  local total_flex = 0
  local gap = self.gap

  for _, child in ipairs(self.children) do
    local child_size = child:getSize()
    max_align = math.max(child_size[dir.align_dimension], max_align)
    total_flex = total_flex + child_size[dir.flex_dimension]
  end

  if not gap then
    if children_count > 1 and self.justify_content == SPACE_BETWEEN then
      gap = (size[dir.flex_dimension] - total_flex) / (children_count - 1)
    else
      gap = 0
    end
  end

  local elements = {}
  if self.children then
    for i, child in ipairs(self.children) do
      table.insert(elements, child)
      if self.align_items == STRETCH then
        child[dir.align_long] = max_align
      end
      if i ~= children_count then
        table.insert(elements, dir.span_class:new {
          width = gap
        })
      end
    end
  end

  local wrapper_class
  if self.justify_content == FLEX_START or self.justify_content == SPACE_BETWEEN then
    wrapper_class = dir.flex_start_class
  elseif self.justify_content == FLEX_END then
    wrapper_class = dir.flex_end_class
  else
    wrapper_class = CenterContainer
  end

  local container = dir.container_class:new {
    align = container_align,
    table.unpack(elements)
  }
  self.children = nil
  local container_size = container:getSize()

  self[1] = wrapper_class:new {
    dimen = {
      [dir.align_dimension] = container_size[dir.align_dimension],
      [dir.flex_dimension] = size[dir.flex_dimension]
    },
    container
  }
end

return Flex
