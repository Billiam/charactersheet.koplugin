local Button = require("ui/widget/button")
local _ = require("gettext")
local TopContainer = require("ui/widget/container/topcontainer")
local logger = require("logger")

local tick_images = {
  "icon/check_1.svg",
  "icon/check_2.svg",
  "icon/check_3.svg",
  "icon/check_4.svg",
}

local ProgressCheckbox = TopContainer:extend{
  value = 0,
  width = 30,
  height = 24,
  callback = nil,
  margin = nil,
  path = ""
}

function ProgressCheckbox:getSize()
  return {w = self.width, h = self.height }
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
end

function ProgressCheckbox:init()
  local callback = self.callback or function() self:increment() end

  self.button = Button:new {
    width = 25,
    height = 25,
    padding = 0,
    text_font_size = 16,
    icon = "",
    icon_width = 23,
    icon_height = 23,
    margin = 0,
    bordersize = 1,
    callback = callback
  }
  self:update()

  self[1] = self.button
end

return ProgressCheckbox
