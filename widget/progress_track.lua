local Device = require("device")
local _ = require("gettext")
local logger = require("logger")

local Geom = require("ui/geometry")
local UIManager = require("ui/uimanager")

local Button = require("ui/widget/button")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local HorizontalSpan = require("ui/widget/horizontalspan")
local ButtonDialog = require("ui/widget/buttondialog")
local ProgressCheckbox = require("widget/progress_checkbox")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")

local TopContainer = require("ui/widget/container/topcontainer")

local InputButton = require("widget/input_button")

local Screen = Device.screen

local DIFFICULTIES = {
  Troublesome = 12,
  Dangerous = 8,
  Formidable = 4,
  Extreme = 2,
  Epic = 1
}

local DIFFICULTY_ORDER = {
  "Troublesome",
  "Dangerous",
  "Formidable",
  "Extreme",
  "Epic"
}

local ProgressTrack = TopContainer:extend {
  spacing = Screen:scaleBySize(5),
  checkbox_size = Screen:scaleBySize(36),
  path = nil,

  show_difficulty = true,
  show_label = true,

  callback = nil,
  name = nil,

  _increment_value = 1,

  data = {
    difficulty = "Epic",
    description = "",
    value = 0
  }
}

function ProgressTrack:getSize()
  return { w = self.width, h = self.height }
end

function ProgressTrack:decrement()
  self.data.value = math.max(0, self.data.value - self._increment_value)
end

function ProgressTrack:increment()
  self.data.value = math.min(40, self.data.value + self._increment_value)
end

function ProgressTrack:clear()
  self.data.value = 0
  self:update()
end

function ProgressTrack:update()
  local total = self.data.value
  for i = 1, 10 do
    local value = math.min(4, total)
    total = total - value
    if self.checkboxes[i].value ~= value then
      self.checkboxes[i].value = value
      self.checkboxes[i]:update()
    end
  end

  self:updateValue()
end

function ProgressTrack:updateValue()
  self.callback(self.name, self.data)
end

function ProgressTrack:setDifficulty(difficulty)
  self.data.difficulty = difficulty
  self._increment_value = DIFFICULTIES[difficulty]
end

function ProgressTrack:updateDifficulty(difficulty)
  self:setDifficulty(difficulty)
  if self.show_difficulty then
    self.difficulty_button:setText(self.data.difficulty, self.difficulty_button:getSize().w)
    UIManager:setDirty(self.show_parent, "ui", self.difficulty_button.dimen)
  end
end

function ProgressTrack:showDifficultySelect()
  local dialog
  local buttons = {}
  for _, key in ipairs(DIFFICULTY_ORDER) do
    local active = self.data.difficulty == key

    local button = {
      text = key .. (active and " ★" or ""),
      callback = function()
        self:updateDifficulty(key)
        UIManager:close(dialog)
      end
    }
    table.insert(buttons, { button })
  end

  dialog = ButtonDialog:new {
    buttons = buttons
  }
  UIManager:show(dialog)
end

function ProgressTrack:init()
  self.checkboxes = {}
  self.height = self.height or self.checkbox_size + 5
  local spacing = self.spacing

  self:setDifficulty(self.data.difficulty)

  spacing = spacing or (self.width - (self.checkbox_size) * 10) / 9

  self.checkboxes = self:_buildCheckboxes()
  local checkbox_content = {}

  for i = 1, 10 do
    table.insert(checkbox_content, self.checkboxes[i])
    if i < 10 then
      table.insert(checkbox_content, HorizontalSpan:new { width = spacing })
    end
  end
  local CenterContainer = require("ui/widget/container/centercontainer")

  local vgroup_contents = {
    CenterContainer:new {
      dimen = Geom:new {
        w = self.width,
        h = self.checkbox_size
      },
      HorizontalGroup:new {
        table.unpack(checkbox_content)
      }
    }
  }

  if self.show_label then
    local input_width = self.width

    if self.show_difficulty then
      self.difficulty_button = Button:new {
        padding = 0,
        text_font_size = 16,
        bordersize = 0,
        text = "Troublesome",
        callback = function()
          self:showDifficultySelect()
        end
      }
      self.difficulty_button:setText(self.data.difficulty, self.difficulty_button:getSize().w)
      input_width = input_width - self.difficulty_button.width - 5
    end

    local label_group = HorizontalGroup:new {
      InputButton:new {
        input = "",
        hint = "Vow",
        width = input_width,
        parent = self,
        underline_size = 1,
        name = "description",
        callback = function(name, value)
          self.data[name] = value
          self:updateValue()
        end,
      },
      self.difficulty_button
    }
    table.insert(vgroup_contents, 1, label_group)
    table.insert(vgroup_contents, 2, VerticalSpan:new {
      width = Screen:scaleBySize(5)
    })
    self.height = self.height + label_group:getSize().h
  end

  local vgroup = VerticalGroup:new {
    align = "left",
    table.unpack(vgroup_contents)
  }
  self[1] = vgroup
end

function ProgressTrack:_buildCheckboxes()
  local total = self.data.value
  local checkboxes = {}

  for i = 1, 10 do
    local value = math.min(4, total)
    total = total - value

    checkboxes[i] = ProgressCheckbox:new {
      value = value,
      path = self.path,
      width = self.checkbox_size,
      height = self.checkbox_size,
      callback = function()
        self:selectCheckbox(i)
      end
    }
  end

  return checkboxes
end

function ProgressTrack:updateCheckboxDifficulty()
  self.data.value = math.floor(self.data.value / self._increment_value) * self._increment_value
  self:update()
end

function ProgressTrack:selectCheckbox(i)
  local start_value = (i - 1) * 4 + self.checkboxes[i].value
  local next_value = (math.floor(start_value / self._increment_value) + 1) * self._increment_value

  if self.checkboxes[i].value > 0 and next_value > i * 4 then
    next_value = math.floor((i - 1) * 4 / self._increment_value) * self._increment_value
  end

  self.data.value = next_value
  self:update()
end

return ProgressTrack
