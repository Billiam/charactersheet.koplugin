local Device = require("device")
local _ = require("gettext")
local logger = require("logger")

local UIManager = require("ui/uimanager")

local Button = require("ui/widget/button")
local ButtonDialog = require("ui/widget/buttondialog")
local ProgressCheckbox = require("charsheet/widget/ironsworn/progress_checkbox")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")

local TopContainer = require("ui/widget/container/topcontainer")

local _t = require("charsheet/lib/table_util")
local FlexContainer = require("charsheet/widget/flex_container")
local InputButton = require("charsheet/widget/input_button")

local Screen = Device.screen
logger.warn("DOTS", ...)
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
  value = nil,
}

function ProgressTrack:getSize()
  if not self.width or not self.height then
    local size = self[1]:getSize()

    self.width = self.width or size.w
    self.height = self.height or size.h
  end

  return { w = self.width, h = self.height }
end

function ProgressTrack:decrement()
  self.value.value = math.max(0, self.value.value - self._increment_value)
end

function ProgressTrack:increment()
  self.value.value = math.min(40, self.value.value + self._increment_value)
end

function ProgressTrack:clear()
  self.value.value = 0
  self:update()
end

function ProgressTrack:update()
  local total = self.value.value
  for i = 1, 10 do
    local value = math.min(4, total)
    total = total - value
    if self.checkboxes[i].value ~= value then
      self.checkboxes[i].value = value
      self.checkboxes[i]:update()
    end
  end
end

function ProgressTrack:onUpdateValue()
  self.callback(self.name, self.value)
end

function ProgressTrack:setDifficulty(difficulty)
  self.value.difficulty = difficulty
  self._increment_value = DIFFICULTIES[difficulty]
end

function ProgressTrack:updateDifficulty(difficulty)
  logger.warn("Updating difficulty to", difficulty)
  self:setDifficulty(difficulty)
  if self.show_difficulty then
    logger.warn("Showing difficulty")
    self.difficulty_button:setText(difficulty, self.difficulty_button:getSize().w)
    UIManager:setDirty(self.show_parent, "ui", self.difficulty_button.dimen)
  end
end

function ProgressTrack:showDifficultySelect()
  local dialog
  local buttons = {}
  for _, key in ipairs(DIFFICULTY_ORDER) do
    local active = self.value.difficulty == key

    local button = {
      text = key .. (active and " ★" or ""),
      callback = function()
        self:updateDifficulty(key)
        self:onUpdateValue()
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
  self.value = {
    difficulty = "Epic",
    description = "",
    value = 0
  }
  self.checkboxes = {}
  self.height = self.height or self.checkbox_size + 5

  self:setDifficulty(self.value.difficulty)

  self.checkboxes = self:_buildCheckboxes()
  local checkbox_content = {}

  for i = 1, 10 do
    checkbox_content[i] = self.checkboxes[i]
  end

  local vgroup_contents = {
    FlexContainer:new {
      width = self.width,
      justify_content = FlexContainer.CENTER,
      gap = self.spacing,
      children = checkbox_content,
    },
  }
  if not self.width then
    self.width = vgroup_contents[1]:getSize().w
  end

  if self.show_label or self.show_difficulty then
    local label_flex_children = {}
    local input_width = self.width

    if self.show_difficulty then
      self.difficulty_button = Button:new {
        padding = 0,
        text_font_size = 16,
        bordersize = 0,
        text = "Troublesome",
        margin = 0,
        callback = function()
          self:showDifficultySelect()
        end
      }
      self.difficulty_button:setText(self.value.difficulty, self.difficulty_button:getSize().w)

      input_width = input_width - self.difficulty_button.width --- Screen:scaleBySize(5)
      label_flex_children[self.show_label and 2 or 1] = self.difficulty_button
    end

    if self.show_label then
      self.description = InputButton:new {
        input = "",
        hint = "Vow",
        width = input_width,
        parent = self,
        underline_size = 1,
        name = "description",
        callback = function(name, value)
          self.value[name] = value
          self:onUpdateValue()
        end,
      }
      label_flex_children[1] = self.description
    end

    local label_group = FlexContainer:new {
      children = label_flex_children
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
  local total = self.value.value
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
  self.value.value = math.floor(self.value.value / self._increment_value) * self._increment_value
  self:update()
end

function ProgressTrack:selectCheckbox(i)
  local start_value = (i - 1) * 4 + self.checkboxes[i].value
  local next_value = (math.floor(start_value / self._increment_value) + 1) * self._increment_value

  if self.checkboxes[i].value > 0 and next_value > i * 4 then
    next_value = math.floor((i - 1) * 4 / self._increment_value) * self._increment_value
  end

  self.value.value = next_value
  self:update()
  self:onUpdateValue()
end

function ProgressTrack:updateValue(value)
  local previous_value = self.value
  local changed = false
  self.value = _t.clone(value)

  if self.value.difficulty ~= previous_value.difficulty then
    changed = true
    self:updateDifficulty(value.difficulty)
  end

  if self.description and self.value.description ~= previous_value.description then
    changed = true
    self.description:updateValue(value.description)
  end

  if changed or self.value.value ~= previous_value.value then
    self:update()
  end
end

return ProgressTrack
