local Button = require("ui/widget/button")
local _ = require("gettext")
local logger = require("logger")
local InputContainer = require("ui/widget/container/inputcontainer")
local tick_images = {
  "icon/check_1.svg",
  "icon/check_2.svg",
  "icon/check_3.svg",
  "icon/check_4.svg",
}

local ProgressCheckbox = InputContainer:extend {
  value = 0,
  width = 25,
  height = 25,
  margin = nil,
  path = "",

  callback = nil,
  name = nil,
}

function ProgressCheckbox:getSize()
  return { w = self.width, h = self.height }
end

function ProgressCheckbox:update()
  local icon = self.button.label_widget
  if self.value == 0 then
    icon.hide = true
  else
    icon.hide = false
    icon:free()
    icon._bb = nil
    icon.file = self.path .. "/" .. tick_images[self.value]
    icon:init()
  end

  self.button:refresh()
end

function ProgressCheckbox:increment()
  self.value = self.value < 4 and (self.value + 1) or 0
  self:update()

  self.callback(self.name, self.value)
end

function ProgressCheckbox:init()
  local callback = self.callback or function() self:increment() end

  self.button = Button:new {
    width = self.width,
    height = self.height - 2, -- inner frame border handles size inconsistently
    padding = 0,
    text_font_size = 16,
    icon = "",
    icon_width = self.width - 4,
    icon_height = self.height - 4,
    margin = 0,
    bordersize = 1,
    callback = callback
  }
  self:update()

  self[1] = self.button
end

function ProgressCheckbox:updateValue(value)
  self.value = value
  self:update()
end

return ProgressCheckbox
