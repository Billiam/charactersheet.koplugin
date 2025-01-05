local _ = require("gettext")
local Device = require("device")
local T = require("ffi/util").template

local Geom = require("ui/geometry")
local UIManager = require("ui/uimanager")

local Button = require("ui/widget/button")
local LineWidget = require("ui/widget/linewidget")
local VerticalGroup = require("ui/widget/verticalgroup")

local FrameContainer = require("ui/widget/container/framecontainer")
local InputContainer = require("ui/widget/container/inputcontainer")
local ScrollableContainer = require("ui/widget/container/scrollablecontainer")

local Flex = require("widget/flex")

local Screen = Device.screen

local Pager = InputContainer:extend {
  page = 1,
  pages = nil,
  width = nil,
  height = nil,

  scroll_bar_width = Screen:scaleBySize(6),
  padding_left = 5,
}

function Pager:init()
  self.pages = self.pages or {}
  self.pages[1] = self.pages[1] or {}
  self.total_pages = #self.pages
  self.page = math.min(self.total_pages, math.max(self.page, 1))

  self.cropping_widget = self:buildContainer(self.pages[self.page])

  local first_page_button = Button:new {
    callback = function() self:firstPage() end,
    bordersize = 0,
    icon = "chevron.first",

    enabled_func = function()
      return self.page > 1
    end
  }
  local last_page_button = Button:new {
    callback = function() self:lastPage() end,
    bordersize = 0,
    icon = "chevron.last",

    enabled_func = function()
      return self.page < self.total_pages
    end
  }
  local next_page_button = Button:new {
    callback = function() self:nextPage() end,
    bordersize = 0,
    icon = "chevron.right",

    enabled_func = function()
      return self.page < self.total_pages
    end
  }
  local previous_page_button = Button:new {
    callback = function() self:previousPage() end,
    bordersize = 0,
    icon = "chevron.left",

    enabled_func = function()
      return self.page > 1
    end
  }
  self.page_info_text = Button:new {
    bordersize = 0,
    text = "",
    hold_input = {
      title = _("Enter page number"),
      input_type = "number",
      hint_func = function()
        return string.format("(1 - %s)", self.total_pages)
      end,
      callback = function(input)
        local page = tonumber(input)
        if page and page >= 1 and page <= self.total_pages then
          self:goToPage(page)
        end
      end,
      ok_text = _("Go to page"),
    },
    call_hold_input_on_tap = true,
  }
  self:updatePageText()

  local controls = Flex:new {
    justify_content = Flex.SPACE_BETWEEN,
    align_items = Flex.STRETCH,
    width = self.width,
    children = {
      first_page_button,
      previous_page_button,
      self.page_info_text,
      next_page_button,
      last_page_button,
    }
  }

  local control_size = controls:getSize()
  self.scroll_height = self.height - control_size.h - 1
  local contents = {
    self.cropping_widget,
    LineWidget:new {
      dimen = Geom:new {
        w = self.width,
        h = 1
      }
    },
  }
  if self.total_pages > 1 then
    self.cropping_widget.dimen.h = self.scroll_height
    table.insert(contents, controls)
  end

  local v_group = VerticalGroup:new {
    table.unpack(contents)
  }

  self[1] = v_group
end

function Pager:updatePageText()
  self.page_info_text:setText(T(_("Page %1 of %2"), self.page, self.total_pages))
  if self.total_pages > 1 then
    self.page_info_text:enable()
  else
    self.page_info_text:disableWithoutDimming()
  end
end

function Pager:nextPage()
  if self.page < self.total_pages then
    self:goToPage(self.page + 1)
  end
end

function Pager:previousPage()
  if self.page > 1 then
    self:goToPage(self.page - 1)
  end
end

function Pager:firstPage()
  self:goToPage(1)
end

function Pager:lastPage()
  if self.page < self.total_pages then
    self:goToPage(self.total_pages)
  end
end

function Pager:buildContainer(page_content)
  return ScrollableContainer:new {
    scroll_bar_width = self.scroll_bar_width,
    dimen = Geom:new {
      w = self.width,
      h = self.height
    },
    ignore_events = {
      "touch"
    },
    show_parent = self.show_parent,
    FrameContainer:new {
      padding = 0,
      padding_left = self.padding_left,
      bordersize = 0,
      width = self.width,
      table.unpack(page_content)
    }
  }
end

function Pager:goToPage(page)
  self.page = page

  self:updatePageText()

  for i, _ in ipairs(self.cropping_widget[1]) do
    self.cropping_widget[1][i] = nil
  end
  for i, n in ipairs(self.pages[page]) do
    self.cropping_widget[1][i] = n
  end

  self.cropping_widget._crop_w = nil
  self.cropping_widget._crop_h = nil
  self.cropping_widget:initState()

  UIManager:setDirty(self.show_parent, "ui", self.dimen)
end

return Pager
