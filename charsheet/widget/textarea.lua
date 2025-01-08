local Blitbuffer = require("ffi/blitbuffer")
local Font = require("ui/font")
local InputDialog = require("ui/widget/inputdialog")
local UIManager = require("ui/uimanager")
local ScrollTextWidget = require("ui/widget/scrolltextwidget")

local Textarea = ScrollTextWidget:extend {
  callback = nil,
  name = nil,
  font_size = 16
}

function Textarea:init()
  self.face = Font:getFace("cfont", self.font_size)
  local restore_text = self.text

  if not self.text or self.text == "" then
    self.fgcolor = Blitbuffer.COLOR_GRAY
    self.text = self.hint
  end

  ScrollTextWidget.init(self)
  self.text = restore_text
end

function Textarea:setValue(text)
  if self.text == text then
    return
  end

  if text and text ~= "" then
    self.text_widget.fgcolor = Blitbuffer.COLOR_BLACK
    self.text_widget:setText(text)
  else
    self.text_widget.fgcolor = Blitbuffer.COLOR_GRAY
    self.text_widget:setText(self.hint)
  end

  self.prev_low = nil
  self:updateScrollBar()
  self.text = text
  self:scrollToTop()
end

function Textarea:onTapScrollText(arg, ges)
  local dialog
  dialog = InputDialog:new {
    title = self.label,
    input = self.text,
    input_hint = self.hint,
    allow_newline = true,
    save_callback = function(value)
      UIManager:close(dialog)
      self:setValue(value)
      self.callback(self.name, value)

      -- fix scroll after update
      return false, false
    end
  }
  UIManager:show(dialog)
  dialog:onShowKeyboard()
  return true
end

function Textarea:updateValue(value)
  self:setValue(value)
end

return Textarea
