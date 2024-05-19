#==============================================================================
# ** Level Up Item Reward - 1.0
# ** by athosfranco - 15/05/2024
#------------------------------------------------------------------------------
#  This script gives a specific item every time the player levels up after
#  reaching a certain level.
#==============================================================================

module LevelUpItemReward
  # ========================== SCRIPT CONFIGURATION ===========================
  
  # Set whether to use a switch to control if the player will receive the item
  USE_SWITCH = false
  
  # Set the switch ID that controls the item giving
  SWITCH_ID = 1
  
  # Set the item ID that the player will receive
  ITEM_ID = 300
  
  # Set the level after which the player should start receiving the item
  LEVEL_THRESHOLD = 10
  
  # Set the interval of levels at which the item is given
  LEVEL_INTERVAL = 1 
  
  # Set whether the message should be shown
  SHOW_MESSAGE = true
  
  # Set the message shown when the player receives the item
  MESSAGE_PREFIX = "You got"  
  MESSAGE_SUFFIX = "for leveling up!" 
  
end

class Game_Actor < Game_Battler
  alias level_up_item_reward_level_up level_up
  
  #--------------------------------------------------------------------------
  # * DONT CHANGE ANYTHING BELOW HERE - UNLESS YOU KNOW WHAT YOU'RE DOING
  #--------------------------------------------------------------------------
  def level_up
    level_up_item_reward_level_up
    if level > LevelUpItemReward::LEVEL_THRESHOLD && (level - LevelUpItemReward::LEVEL_THRESHOLD) % LevelUpItemReward::LEVEL_INTERVAL == 0
      if !LevelUpItemReward::USE_SWITCH || $game_switches[LevelUpItemReward::SWITCH_ID]
        $game_party.gain_item($data_items[LevelUpItemReward::ITEM_ID], 1)
        
        # Correctly reference the constants in the LevelUpItemReward module
        message_prefix = LevelUpItemReward::MESSAGE_PREFIX
        message_suffix = LevelUpItemReward::MESSAGE_SUFFIX
        item = $data_items[LevelUpItemReward::ITEM_ID]
        
        # Add the item icon to the message if SHOW_MESSAGE is true
        if LevelUpItemReward::SHOW_MESSAGE
          $game_message.add("#{message_prefix} \\i[#{item.icon_index}] #{item.name} #{message_suffix}")
        end
      end
    end
  end
end
