local InputDialog = require("ui/widget/inputdialog")
local UIManager = require("ui/uimanager")
local ScrollTextWidget = require("ui/widget/scrolltextwidget")

local Textarea = ScrollTextWidget:extend {
  callback = nil,
  name = nil,
}

function Textarea:setValue(text)
  if self.text == text then
    return
  end

  self.text_widget:setText(text)
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
