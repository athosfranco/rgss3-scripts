#==============================================================================
# ** Item Popup Notifier
#------------------------------------------------------------------------------
# Author: Athos Franco - athos.francof@gmail.com
# License: Free for personal/commercial use with attribution.
#------------------------------------------------------------------------------
# Description:
# Displays an automatic popup window when the player receives items or gold.
# - Compatible with ItemRarity (Hime)
# - Dynamically adds to the same window if it's still on-screen
# - Fade in/out effect
# - Gold support with custom icon/name
# - Optional top label message (e.g., "You found:")
# - Custom text alignment
# - Optionally controlled by a game switch
#------------------------------------------------------------------------------
# Configuration module below
#==============================================================================
module ItemPopupConfig
  # Opacity of the popup window (0 = transparent, 255 = solid)
  WINDOW_OPACITY     = 200

  # Where the popup appears on screen
  # Valid values:
  # :center          => exact center of screen
  # :center_above    => slightly above center (avoids player overlap)
  # :top_left        => top-left corner
  # :top_right       => top-right corner
  # :bottom_left     => bottom-left corner
  # :bottom_right    => bottom-right corner
  WINDOW_POSITION    = :center_above

  # Number of frames the popup remains fully visible (60 = 1 second)
  AUTO_CLOSE_TIME    = 120

  # Duration of fade-in and fade-out animations (in frames)
  FADE_TIME          = 15

  # Font settings
  FONT_SIZE          = 16
  LINE_HEIGHT        = 24
  PADDING            = 12

  # Sound effect played when an item is added (nil to disable)
  GAIN_ITEM_SOUND    = "Item3"

  # Gold item configuration
  GOLD_ICON_INDEX    = 2114
  GOLD_NAME          = "Gold"

  # Ignore notifications for losing items/gold
  IGNORE_NEGATIVE    = true

  # If greater than 0, popup will only appear if this switch is ON
  POPUP_SWITCH_ID    = 0

  # Optional label displayed above items (e.g., "You found:")
  SHOW_HEADER        = true
  HEADER_TEXT        = "You found:"
  HEADER_COLOR       = Color.new(255, 255, 0)

  # Alignment of the item text: :left, :center, or :right
  TEXT_ALIGNMENT     = :center
end

#==============================================================================
# ** ItemPopupManager - Controls popup creation and updates
#==============================================================================
class ItemPopupManager
  def initialize
    @window = nil
  end

  def show(item, amount)
    return if ItemPopupConfig::IGNORE_NEGATIVE && amount <= 0
    return if ItemPopupConfig::POPUP_SWITCH_ID > 0 &&
              !$game_switches[ItemPopupConfig::POPUP_SWITCH_ID]

    if @window && !@window.disposed?
      @window.add_or_accumulate_item(item, amount)
    else
      @window = ItemPopupWindow.new([[item, amount]])
    end
  end

  def update
    @window.update if @window
    if @window && @window.finished?
      @window.dispose
      @window = nil
    end
  end
end

#==============================================================================
# ** GoldPopupItem - Dummy object to treat gold like an item
#==============================================================================
class GoldPopupItem
  def name; ItemPopupConfig::GOLD_NAME; end
  def icon_index; ItemPopupConfig::GOLD_ICON_INDEX; end
  def rarity_colour; Color.new(255, 255, 255); end
end

#==============================================================================
# ** ItemPopupWindow - The popup window itself
#==============================================================================
class ItemPopupWindow < Window_Base
  def initialize(items)
    @items = items
    @timer = ItemPopupConfig::AUTO_CLOSE_TIME
    @fade_time = ItemPopupConfig::FADE_TIME
    @opacity_step = ItemPopupConfig::WINDOW_OPACITY.to_f / @fade_time
    @phase = :fade_in
    width = calc_width
    height = calc_height
    super(calc_x(width), calc_y(height), width, height)
    self.opacity = 0
    create_contents
    contents.font.size = ItemPopupConfig::FONT_SIZE
    refresh
    play_sound
  end

  def add_or_accumulate_item(item, amount)
    existing = @items.find { |it, _| it == item }
    if existing
      existing[1] += amount
    else
      @items << [item, amount]
    end
    @timer = ItemPopupConfig::AUTO_CLOSE_TIME
    resize_and_refresh
    play_sound
  end

  def resize_and_refresh
    new_width = calc_width
    new_height = calc_height
    self.move(calc_x(new_width), calc_y(new_height), new_width, new_height)
    create_contents
    contents.font.size = ItemPopupConfig::FONT_SIZE
    refresh
  end

  def calc_width
    lines = @items.map { |item, amount| "#{item.name} x#{amount}" }
    lines << ItemPopupConfig::HEADER_TEXT if ItemPopupConfig::SHOW_HEADER
    max_length = lines.map(&:length).max || 10
    est_char_width = ItemPopupConfig::FONT_SIZE / 2 + 2
    est_char_width * max_length + 48 + ItemPopupConfig::PADDING * 2
  end

  def calc_height
    extra = ItemPopupConfig::SHOW_HEADER ? 1 : 0
    (@items.size + extra) * ItemPopupConfig::LINE_HEIGHT + ItemPopupConfig::PADDING * 2
  end

  def calc_x(win_w)
    case ItemPopupConfig::WINDOW_POSITION
    when :center, :center_above then (Graphics.width - win_w) / 2
    when :top_left then 16
    when :top_right then Graphics.width - win_w - 16
    when :bottom_left then 16
    when :bottom_right then Graphics.width - win_w - 16
    else (Graphics.width - win_w) / 2
    end
  end

  def calc_y(win_h)
    case ItemPopupConfig::WINDOW_POSITION
    when :center then (Graphics.height - win_h) / 2
    when :center_above then (Graphics.height - win_h) / 2 - 64
    when :top_left, :top_right then 16
    when :bottom_left, :bottom_right then Graphics.height - win_h - 16
    else (Graphics.height - win_h) / 2
    end
  end

  def refresh
    contents.clear
    y = 0

    # Draw optional header text
    if ItemPopupConfig::SHOW_HEADER
      contents.font.color = ItemPopupConfig::HEADER_COLOR
      draw_text(0, y, contents.width, ItemPopupConfig::LINE_HEIGHT, ItemPopupConfig::HEADER_TEXT, alignment)
      y += ItemPopupConfig::LINE_HEIGHT
      change_color(normal_color)
    end

    # Draw each item with aligned icon+text block
    @items.each do |(item, amount)|
      str = "#{item.name} x#{amount}"
      total_width = 24 + 4 + text_width(str) # icon + padding + text

      base_x = case ItemPopupConfig::TEXT_ALIGNMENT
               when :left   then 0
               when :center then (contents.width - total_width) / 2
               when :right  then contents.width - total_width
               else 0
               end

      icon_x = base_x
      text_x = base_x + 28

      change_color(item.rarity_colour) if item.respond_to?(:rarity_colour)
      draw_icon(item.icon_index, icon_x, y)
      draw_text(text_x, y, contents.width - text_x, ItemPopupConfig::LINE_HEIGHT, str)
      change_color(normal_color)
      y += ItemPopupConfig::LINE_HEIGHT
    end
  end

  def text_width(str)
    temp = Bitmap.new(1, 1)
    temp.font.size = ItemPopupConfig::FONT_SIZE
    width = temp.text_size(str).width
    temp.dispose
    width
  end

  def alignment
    case ItemPopupConfig::TEXT_ALIGNMENT
    when :left   then 0
    when :center then 1
    when :right  then 2
    else 0
    end
  end

  def play_sound
    return unless ItemPopupConfig::GAIN_ITEM_SOUND
    RPG::SE.new(ItemPopupConfig::GAIN_ITEM_SOUND).play
  end

  def update
    super
    case @phase
    when :fade_in
      self.opacity += @opacity_step
      @phase = :hold if self.opacity >= ItemPopupConfig::WINDOW_OPACITY
    when :hold
      @timer -= 1
      @phase = :fade_out if @timer <= 0
    when :fade_out
      self.opacity -= @opacity_step
    end
  end

  def finished?
    self.opacity <= 0 && @phase == :fade_out
  end
end

#==============================================================================
# ** Scene_Map - Hook into map update
#==============================================================================
class Scene_Map < Scene_Base
  alias item_popup_start start
  alias item_popup_update update

  def start
    item_popup_start
    @item_popup = ItemPopupManager.new
  end

  def update
    item_popup_update
    @item_popup.update
  end

  def popup_manager
    @item_popup
  end
end

#==============================================================================
# ** Game_Party - Hook gain_item and gain_gold
#==============================================================================
class Game_Party < Game_Unit
  alias item_popup_gain_item gain_item
  alias item_popup_gain_gold gain_gold

  def gain_item(item, amount, include_equip = false)
    item_popup_gain_item(item, amount, include_equip)
    if SceneManager.scene_is?(Scene_Map) && item && amount != 0
      SceneManager.scene.popup_manager.show(item, amount)
    end
  end

  def gain_gold(amount)
    item_popup_gain_gold(amount)
    return if ItemPopupConfig::IGNORE_NEGATIVE && amount <= 0
    if SceneManager.scene_is?(Scene_Map)
      SceneManager.scene.popup_manager.show(GoldPopupItem.new, amount)
    end
  end
end
