local WidgetContainer = require("ui/widget/container/widgetcontainer")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")

local Checkbox = require("widget/checkbox")

local Checklist = WidgetContainer:extend {
  options = {},
  value = nil,
  horizontal = false,
  label_size = 16,

  checkbox_size = 20
}

function Checklist:init()
  local elements = {}
  self.value = self.value or {}

  local callback = function(name, value)
    self.value[name] = value

    self.callback(self.name, self.value)
  end

  local option_count = #self.options
  for i, v in ipairs(self.options) do
    local checkbox = Checkbox:new {
      name = v.name,
      text = v.label,
      font_size = self.label_size,
      width = self.checkbox_size,
      margin = 5,
      checked = self.value[v.name],
      callback = callback,
      show_parent = self.show_parent,
    }
    table.insert(elements, checkbox)
    if i < option_count then
      table.insert(elements, VerticalSpan:new { width = 2 })
    end
  end

  local containerType = self.horizontal and HorizontalGroup or VerticalGroup
  local align = self.horizontal and "top" or "left"
  local container = containerType:new {
    align = align,
    table.unpack(elements)
  }

  self[1] = container
end

return Checklist
