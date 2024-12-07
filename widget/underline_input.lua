local Size = require("ui/size")
local UnderlineContainer = require("ui/widget/container/underlinecontainer")
local Button = require("ui/widget/button")
local InputDialog = require("ui/widget/inputdialog")
local UIManager = require("ui/uimanager")
local logger = require("logger")
local Blitbuffer = require("ffi/blitbuffer")

local Device = require("device")
local Screen = Device.screen

local UnderlineInput = UnderlineContainer:extend{
  value = nil,
  color = Blitbuffer.COLOR_BLACK,
  bold = false,
  linesize = Size.line.thin,
  width = Screen:scaleBySize(50),

  hint = "name",
  align = "left",
}

function UnderlineInput:init()
  local show_hint = self.input == nil or self.input == ""
  local text_value = show_hint and self.hint or self.input

  self.button = Button:new{
    bordersize = 0,
    text = text_value,
    text_font_bold = false,
    padding = 0,
    align = self.align,
    width = self.width,
    margin = 0,
    callback = function()

      local dialog
      dialog = InputDialog:new{
        title = self.label,
        input = self.input,
        input_hint = self.hint,
        save_callback = function(value)

          UIManager:close(dialog)
          self:setValue(value, true)
          -- TODO: notify something about data change
          return false, false
        end
      }
      UIManager:show(dialog)
      dialog:onShowKeyboard()
    end
  }

  if show_hint then
    self.button.label_widget.fgcolor = Blitbuffer.COLOR_GRAY
  end

  self[1] = self.button
end

function UnderlineInput:setValue(text, refresh)
  self.input = text

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

return UnderlineInput
