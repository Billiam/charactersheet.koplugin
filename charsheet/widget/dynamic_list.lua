local Device = require("device")
local logger = require("logger")
local _ = require("gettext")

local UIManager = require("ui/uimanager")

local Button = require("ui/widget/button")
local ConfirmBox = require("ui/widget/confirmbox")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")

local InputContainer = require("ui/widget/container/inputcontainer")

local _t = require("charsheet/lib/table_util")

local FlexContainer = require("charsheet/widget/flex_container")
local TemplateWidget = require("charsheet/widget/template_widget")

local Screen = Device.screen

local DynamicList = InputContainer:extend {
  align = "left",
  template = nil,
  name = nil,
  input_callback = nil,
  plugin_path = nil,
  add_item_label = nil,
  add_item_func = nil
}

function DynamicList:init()
  if not self.data then
    self.data = {}
  end
  if #self.data == 0 then
    self.data[1] = {}
  end

  local children = {}
  for i, data in ipairs(self.data) do
    children[i] = self:buildWidget(data)
  end

  self.container = VerticalGroup:new {
    table.unpack(children)
  }
  if self.add_item_func then
    self.add_button = self.add_item_func()
  else
    self.add_button = Button:new {
      text = self.add_item_label or "Add",
      margin = 0,
      radius = Screen:scaleBySize(5),
      callback = function()
        self:addItem()
      end
    }
  end

  self[1] = VerticalGroup:new {
    align = self.align,
    self.container,
    self.add_button,
  }
end

function DynamicList:buildWidget(data)
  local widget

  local getWidgetIndex = function()
    return _t.find(self.container, widget)
  end

  widget = VerticalGroup:new {
    FlexContainer:new {
      direction = FlexContainer.HORIZONTAL,
      justify_content = FlexContainer.SPACE_BETWEEN,
      width = self.width,
      children = {
        TemplateWidget:new {
          template = {
            self.template,
          },
          input_callback = function(name, value)
            local i = getWidgetIndex()
            self.data[i][name] = value
            self.callback(self.name, self.data)
          end,
          data = data,
          plugin_path = self.plugin_path
        },
        Button:new {
          icon = "cancel",
          radius = Screen:scaleBySize(5),
          callback = function()
            UIManager:show(ConfirmBox:new {
              text = _("Remove item?"),
              ok_callback = function()
                local i = getWidgetIndex()
                self:removeItem(i)
              end
            })
          end
        }
      }
    },
    VerticalSpan:new {
      width = 10
    }
  }

  return widget
end

function DynamicList:addItem()
  -- data could have defaults
  local row = {}
  table.insert(self.data, row)
  table.insert(self.container, self:buildWidget(row))

  self:refresh()
end

function DynamicList:removeItem(i)
  table.remove(self.container, i)
  table.remove(self.data, i)

  self:refresh()
end

function DynamicList:resetLayout()
  self.dimen = nil
end

function DynamicList:refresh()
  self:resetLayouts()
  UIManager:setDirty(self.show_parent, "ui")
end

local recursiveReset
recursiveReset = function(widget, updated_widget)
  local contains_target

  if type(widget) ~= "table" then
    return
  end

  for _, n in ipairs(widget) do
    local found_widget = n == updated_widget
    if n[1] and not found_widget then
      local child_contains_target = recursiveReset(n, updated_widget)
      contains_target = contains_target or child_contains_target
    end
    contains_target = contains_target or found_widget

    if contains_target then
      if n.resetLayout then
        n:resetLayout()
        n.dimen = nil
      end
      if n.initState and n._is_scrollable ~= nil then
        n._is_scrollable = nil
      end
    end
  end

  return contains_target
end


function DynamicList:resetLayouts()
  recursiveReset(self.show_parent, self.container)
end

function DynamicList:updateValue(value)
  -- dynamic lists don't yet support external updates
  return
end

return DynamicList
