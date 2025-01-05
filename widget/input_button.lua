local Size = require("ui/size")
local UnderlineContainer = require("ui/widget/container/underlinecontainer")
local Button = require("widget/button")
local InputDialog = require("ui/widget/inputdialog")
local UIManager = require("ui/uimanager")
local Blitbuffer = require("ffi/blitbuffer")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local FrameContainer = require("ui/widget/container/framecontainer")

local Device = require("device")
local Screen = Device.screen

local InputButton = WidgetContainer:extend {
  value = nil,
  color = Blitbuffer.COLOR_BLACK,
  background = Blitbuffer.COLOR_WHITE,
  bold = false,
  underline_size = Size.line.thin,
  width = Screen:scaleBySize(50),
  bordersize = 0,
  margin = 0,

  font_size = 16,

  callback = nil,
  name = nil,

  hint = "name",
  align = "left",
}

function InputButton:init()
  local show_hint = self.input == nil or self.input == ""
  local text_value = show_hint and self.hint or self.input or ""

  self.button = Button:new {
    bordersize = self.bordersize,
    text = text_value,
    text_font_bold = false,
    padding = 3,
    align = self.align,
    width = self.width,
    margin = 0,
    text_font_size = self.font_size,
    background = self.background,
    callback = function()
      local dialog
      dialog = InputDialog:new {
        title = self.label,
        input = self.input,
        input_hint = self.hint,
        save_callback = function(value)
          UIManager:close(dialog)
          self:setValue(value, true)
          return false, false
        end
      }
      UIManager:show(dialog)
      dialog:onShowKeyboard()
    end
  }

  if show_hint then
    self.button.label_widget.fgcolor = Blitbuffer.COLOR_GRAY_5
  end

  self[1] = FrameContainer:new {
    margin = self.margin,
    bordersize = 0,
    padding = 0,

    UnderlineContainer:new {
      padding = 0,
      linesize = self.underline_size,
      color = self.color,
      self.button
    }
  }
end

function InputButton:setValue(text, refresh)
  self.input = text
  self.callback(self.name, text)

  if text and text ~= "" then
    self.button:setText(text, self.button.width)
    self.button.label_widget.fgcolor = Blitbuffer.COLOR_BLACK
  else
    self.button:setText(self.hint, self.button.width)
    self.button.label_widget.fgcolor = Blitbuffer.COLOR_GRAY
  end

  if refresh then
    self.button:refresh()
  end
end

return InputButton
