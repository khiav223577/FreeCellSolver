class Player
  attr_reader :color_idx
  def initialize(board, color_idx, goal, ai = nil)
    @board = board
    @color_idx = color_idx
    @goal = goal
    @ai = ai
    @move_count = 0
  end
#---------------------------------------------
#  (Select/Deselect) a stone
#---------------------------------------------
  def select_stone(stone)
    deselect_stone
    @prev_select_stone = stone
    stone.selected = true
  end
  def deselect_stone
    return if @prev_select_stone == nil
    @prev_select_stone.selected = nil
    @prev_select_stone = nil
  end
#---------------------------------------------
#  Action
#---------------------------------------------
  def play_a_action(x, y)
    stone = @board.get_stone_by_window_xy(x, y)
    return :invalid if stone == nil
    if @prev_select_stone == nil       #select stone to move(has not selected a stone)
      return :cant_select_others_stone if stone.color_idx != @color_idx
      select_stone(stone)
    elsif @prev_select_stone == stone  #cancle the selection(select the same stone)
      deselect_stone
      return finish! if @move_count > 0 #has jumpped
    elsif @prev_select_stone.color_idx == stone.color_idx #change selection(select another stone with same color)
      select_stone(stone)
    elsif not stone.occupied?          #move stone(select an available place)
      case @prev_select_stone.distance_from(stone)
      when 1 #move
        return :you_had_jumpped if @move_count > 0
        stone.switch_color_with(@prev_select_stone)
        deselect_stone
        return finish!
      when 2 #jump
        middle_stone = @board.get_stone_by_board_xy((stone.bx + @prev_select_stone.bx) / 2, (stone.by + @prev_select_stone.by) / 2)
        return :cant_jump_without_other_stone if not middle_stone.occupied?
        stone.switch_color_with(@prev_select_stone)
        @move_count += 1
        select_stone(stone)
      else
        return :illegal_movement #TODO show message?
      end
    else
      return :this_place_is_occupited
    end
    return :success
  end
  def finish! #finish player's turn
    @move_count = 0
    return :finish
  end
  def check_whether_win_the_game?
    return @goal.all?{|bidx| @board.get_stone_by_bidx(bidx).color_idx == @color_idx }
  end
#---------------------------------------------
#  Update (return :next_turn, :win, :fail, or nil)
#---------------------------------------------
  def update(window)
    if @ai
      players = @board.players.map{|s| s.color_idx }.pack("I*")
      states = @board.get_board_state_for_ai.pack("I*")
      result = Array.new(32, -1).pack("I*") #maximum step number is 32
      goal = [].pack("I*")
      actions = @ai.execute(@color_idx, players, states, goal, result) #TODO finish arguments
      return :fail if mimic_actions(actions) == false
    else
      return if not Input.trigger?(Gosu::MsLeft)
      return if play_a_action(window.mouse_x, window.mouse_y) != :finish
    end
    return :win if check_whether_win_the_game?
    return :next_turn
  end
#---------------------------------------------
#  (For AI) 用陣列模擬玩家操作。回傳是否是合法的操作
#---------------------------------------------
  def play_a_action_by_bidx(bidx)
    play_a_action(*Border::ALL_BOARD_XY[bidx])
  end
  def mimic_actions(actions)
    return false if actions.first == nil
    last_bidx = actions.pop
    action.each{|bidx| return false if play_a_action_by_bidx(bidx) != :success }
    return (play_a_action_by_bidx(last_bidx) == :finish)
  end
end
