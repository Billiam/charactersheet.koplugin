local Font = require("ui/font")

local CheckButton = require("ui/widget/checkbutton")

local Checkbox = CheckButton:extend {
  face = Font:getFace("cfont", 16),
  name = nil
}

function Checkbox:init()
  if self.callback then
    local callback = self.callback

    self.callback = function()
      return callback(self.name, self.checked)
    end
  end
  CheckButton.init(self)
end

return Checkbox
