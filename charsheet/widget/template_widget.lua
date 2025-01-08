local logger = require("logger")

local Blitbuffer = require("ffi/blitbuffer")
local Font = require("ui/font")
local TextWidget = require("ui/widget/textwidget")

local Checkbox = require("charsheet/widget/checkbox")
local Checklist = require("charsheet/widget/checklist")
local FilledCheckbox = require("charsheet/widget/filled_checkbox")
local FlexContainer = require("charsheet/widget/flex_container")
local InputButton = require("charsheet/widget/input_button")
local LegacyTrack = require("charsheet/widget/ironsworn/legacy_track")
local ProgressTrack = require("charsheet/widget/ironsworn/progress_track")
local ShadowContainer = require("charsheet/widget/shadow_container")
local Stat = require("charsheet/widget/stat")
local Textarea = require("charsheet/widget/textarea")
local Divider = require("charsheet/widget/divider")
local Section = require("charsheet/widget/section")

-- useful layout components
local HorizontalSpan = require("ui/widget/horizontalspan")
local VerticalSpan = require("ui/widget/verticalspan")
local RectSpan = require("ui/widget/rectspan")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local VerticalGroup = require("ui/widget/verticalgroup")
local LineWidget = require("ui/widget/linewidget")
local IconWidget = require("ui/widget/iconwidget")
local ScrollHtmlWidget = require("ui/widget/scrollhtmlwidget")
local HtmlBoxWidget = require("ui/widget/htmlboxwidget")
local ProgressWidget = require("ui/widget/progresswidget")

local TopContainer = require("ui/widget/container/topcontainer")
local LeftContainer = require("ui/widget/container/leftcontainer")
local RightContainer = require("ui/widget/container/rightcontainer")
local BottomContainer = require("ui/widget/container/bottomcontainer")
local CenterContainer = require("ui/widget/container/centercontainer")
local FrameContainer = require("ui/widget/container/topcontainer")
local UnderlineContainer = require("ui/widget/container/topcontainer")
local WidgetContainer = require("ui/widget/container/widgetcontainer")

local TemplateWidget = WidgetContainer:extend {
  direction = "vertical",
  align = nil,
  template = nil,
  data = nil,
  plugin_path = nil,
  dialog = nil,
  input_callback = nil,
}

function TemplateWidget:init()
  local group_class = self.direction == "horizontal" and HorizontalGroup or VerticalGroup
  local group = group_class:new { align = self.align }

  self.field_map = {}

  for i, widget_data in ipairs(self.template) do
    group[i] = self:buildWidget(widget_data, self.data)
  end
  self[1] = group
end

function TemplateWidget:scaleWidth(size)
  return math.floor(self.width * size * .01 + 0.5)
end

function TemplateWidget:parseWidth(size)
  if type(size) == "string" then
    if size:sub(-1) == "%" then
      return self:scaleWidth(tonumber(size:sub(1, -2)))
    end
  else
    return size
  end
end

function TemplateWidget:parseColor(color)
  if type(color) == "string" then
    return Blitbuffer["COLOR_" .. string.upper(color)]
  end
end

function TemplateWidget:builders()
  local builder = self

  if not self._builders then
    self._builders = {
      LegacyTrack = {
        new = function(_, data)
          data.path = builder.plugin_path
          return LegacyTrack:new(data)
        end
      },
      Textarea = {
        new = function(_, data)
          data.dialog = builder.dialog
          data.text = data.value
          return Textarea:new(data)
        end
      },
      ProgressTrack = {
        new = function(_, data)
          data.path = builder.plugin_path
          return ProgressTrack:new(data)
        end
      },
      FilledCheckbox = {
        new = function(_, data)
          data.checked = data.value
          return FilledCheckbox:new(data)
        end
      },
      Checkbox = {
        new = function(_, data)
          data.checked = data.value
          return Checkbox:new(data)
        end
      },
      Checklist = Checklist,
      Divider = Divider,
      ShadowContainer = ShadowContainer,
      Stat = Stat,
      TextInput = InputButton,
      FlexContainer = {
        new = function(_, data)
          return FlexContainer:new(data)
        end,
        child_key = "children"
      },
      Section = {
        new = function(_, data)
          return Section:new(data)
        end,
        child_key = "children"
      },

      Text = {
        new = function(_, data)
          return TextWidget:new {
            text = data.text,
            face = Font:getFace("cfont", data.font_size or 16)
          }
        end
      },

      HorizontalSpan = HorizontalSpan,
      VerticalSpan = VerticalSpan,
      RectSpan = RectSpan,
      HorizontalGroup = HorizontalGroup,
      VerticalGroup = VerticalGroup,
      LineWidget = LineWidget,
      IconWidget = IconWidget,
      ScrollHtmlWidget = ScrollHtmlWidget,
      HtmlBoxWidget = HtmlBoxWidget,
      ProgressWidget = ProgressWidget,

      TopContainer = TopContainer,
      LeftContainer = LeftContainer,
      RightContainer = RightContainer,
      BottomContainer = BottomContainer,
      CenterContainer = CenterContainer,
      FrameContainer = FrameContainer,
      UnderlineContainer = UnderlineContainer,
    }
  end

  return self._builders
end

local width_keys = {
  "width", "padding", "spacing"
}

local color_keys = {
  "background", "color", "fgcolor"
}

function TemplateWidget:buildWidget(config, data)
  local type = config.type
  config.type = nil

  local widget_data = {}
  for k, v in pairs(config) do
    widget_data[k] = v
  end

  widget_data.show_parent = self.show_parent

  for _, key in ipairs(width_keys) do
    if widget_data[key] then
      widget_data[key] = self:parseWidth(widget_data[key])
    end
  end
  for _, key in ipairs(color_keys) do
    if widget_data[key] then
      widget_data[key] = self:parseColor(widget_data[key])
    end
  end
  local builders = self:builders()

  if type == "Input" then
    type = config.input_type
    config.input_type = nil

    if config.name then
      widget_data.value = data[config.name]
      widget_data.callback = self.input_callback
    end
  end

  local builder = builders[type]

  if not builder then
    logger.err("Widget type not recognized: " .. type)
    return
  end

  if config.children then
    local child_data = data
    if config.name then
      child_data = data[config.name]
    end

    local children_container = widget_data
    if builder.child_key then
      widget_data[builder.child_key] = {}
      children_container = widget_data[builder.child_key]
    end

    for i, child_config in ipairs(config.children) do
      children_container[i] = self:buildWidget(child_config, child_data)
    end
  end

  if builder then
    local widget = builder:new(widget_data)
    if widget_data.name then
      self.field_map[widget.name] = self.field_map[widget.name] or {}
      table.insert(self.field_map[widget.name], widget)
    end

    return widget
  end
end

function TemplateWidget:onDataUpdate(name, value)
  for _, field in ipairs(self.field_map[name] or {}) do
    if field.value ~= value then
      field:updateValue(value)
    end
  end
end

return TemplateWidget
