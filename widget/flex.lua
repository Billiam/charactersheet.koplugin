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

HorizontalGroup.id = "horizontalgroup"
HorizontalSpan.id = "horizontalspan"
VerticalGroup.id = "verticalgroup"
VerticalSpan.id = "verticalspan"
BottomContainer.id = "BottomContainer"
CenterContainer.id = "centercontainer"
LeftContainer.id = "leftcontainer"
RightContainer.id = "rightcontainer"
TopContainer.id = "topcontainer"
BottomContainer.id = "bottomcontainer"

local Flex = WidgetContainer:extend {
  direction = "horizontal",
  children = nil,
  align_items = "flex-start",
  justify_content = "flex-start",

  width = nil,
  height = nil,
  gap = nil,
}

Flex.SPACE_BETWEEN = "space-between"
Flex.FLEX_START = "flex-start"
Flex.FLEX_END = "flex-end"
Flex.STRETCH = "stretch"
Flex.HORIZONTAL = "horizontal"
Flex.VERTICAL = "vertical"
Flex.CENTER = "center"

local long_dimension = {
  h = "height",
  w = "width",
}
local horizontal = {
  container_class = HorizontalGroup,
  span_class = HorizontalSpan,
  flex_start_class = LeftContainer,
  flex_end_class = RightContainer,

  align_dimension = "h",
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
  flex_dimension = "h",
  align_start = "left",
  align_end = "right",
}

function Flex:init()
  local container_align
  local children_count = #self.children
  self.spans = {}

  local size = {
    w = self.width,
    h = self.height
  }
  local dir = self:dir()

  if self.align_items == Flex.STRETCH or self.align_items == Flex.FLEX_START then
    container_align = dir.align_start
  elseif self.align_items == Flex.FLEX_END then
    container_align = dir.align_end
  end

  local max_align = 0
  self.total_flex = 0
  local gap = self.gap
  for _, child in ipairs(self.children) do
    local child_size = child:getSize()
    max_align = math.max(child_size[dir.align_dimension] or 0, max_align)
    self.total_flex = self.total_flex + (child_size[dir.flex_dimension] or 0)
  end

  if not gap then
    if children_count > 1 and self.justify_content == Flex.SPACE_BETWEEN and size[dir.flex_dimension] then
      gap = (size[dir.flex_dimension] - self.total_flex) / (children_count - 1)
    else
      gap = 0
    end
  end

  local elements = {}
  if self.children then
    for i, child in ipairs(self.children) do
      table.insert(elements, child)

      if self.align_items == Flex.STRETCH then
        local long_flex_key = long_dimension[dir.align_dimension]
        local original_value = child[long_flex_key]
        child[long_flex_key] = max_align

        if original_value ~= max_align and child.updateFlex then
          child:updateFlex(long_flex_key)
        end
      end


      if i ~= children_count then
        local span = dir.span_class:new {
          width = gap
        }
        table.insert(elements, span)
        table.insert(self.spans, span)
      end
    end
  end

  local wrapper_class
  if self.justify_content == Flex.FLEX_START or self.justify_content == Flex.SPACE_BETWEEN then
    wrapper_class = dir.flex_start_class
  elseif self.justify_content == Flex.FLEX_END then
    wrapper_class = dir.flex_end_class
  else
    wrapper_class = CenterContainer
  end

  self.container = dir.container_class:new {
    align = container_align,
    table.unpack(elements)
  }
  local container_size = self.container:getSize()

  self[1] = wrapper_class:new {
    dimen = {
      [dir.align_dimension] = container_size[dir.align_dimension],
      [dir.flex_dimension] = size[dir.flex_dimension] or container_size[dir.flex_dimension]
    },
    self.container
  }
end

function Flex:updateFlex(changed_dimension)
  local dir = self:dir()
  self.container:resetLayout()

  if self.justify_content == Flex.SPACE_BETWEEN and long_dimension[dir.flex_dimension] == changed_dimension then
    if self[changed_dimension] then
      local new_gap = (self[changed_dimension] - self.total_flex) / (#self.children - 1)

      for _, span in ipairs(self.spans) do
        span.width = new_gap
      end
    end
  end
end

function Flex:dir()
  return self.direction == Flex.HORIZONTAL and horizontal or vertical
end

return Flex
