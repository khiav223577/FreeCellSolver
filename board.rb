require File.expand_path('../stone', __FILE__)
require File.expand_path('../player', __FILE__)
require File.expand_path('../gosu/gosu_extension', __FILE__)
class Board
  BASE_ZIDX = 10
  attr_reader :players
  SQRT3_DIVIDE_2 = Math.sqrt(3) / 2.0
  DIVIDE_2 = 1 / 2.0
  ALL_BOARD_XY = [
    [0,0],
    [0,1],[1,0],
    [0,2],[1,1],[2,0],
    [0,3],[1,2],[2,1],[3,0],
    [-4,8],[-3,7],[-2,6],[-1,5],[0,4],[1,3],[2,2],[3,1],[4,0],[5,-1],[6,-2],[7,-3],[8,-4],
    [-3,8],[-2,7],[-1,6],[0,5],[1,4],[2,3],[3,2],[4,1],[5,0],[6,-1],[7,-2],[8,-3],
    [-2,8],[-1,7],[0,6],[1,5],[2,4],[3,3],[4,2],[5,1],[6,0],[7,-1],[8,-2],
    [-1,8],[0,7],[1,6],[2,5],[3,4],[4,3],[5,2],[6,1],[7,0],[8,-1],
    [0,8],[1,7],[2,6],[3,5],[4,4],[5,3],[6,2],[7,1],[8,0],
    [0,9],[1,8],[2,7],[3,6],[4,5],[5,4],[6,3],[7,2],[8,1],[9,0],
    [0,10],[1,9],[2,8],[3,7],[4,6],[5,5],[6,4],[7,3],[8,2],[9,1],[10,0],
    [0,11],[1,10],[2,9],[3,8],[4,7],[5,6],[6,5],[7,4],[8,3],[9,2],[10,1],[11,0],
    [0,12],[1,11],[2,10],[3,9],[4,8],[5,7],[6,6],[7,5],[8,4],[9,3],[10,2],[11,1],[12,0],
    [5,8],[6,7],[7,6],[8,5],
    [6,8],[7,7],[8,6],
    [7,8],[8,7],
    [8,8],
  ]
  ALL_PLAYER_START_AREA = [
    [0,1,2,3,4,5,6,7,8,9],
    [10,11,12,13,23,24,25,35,36,46],
    [19,20,21,22,32,33,34,44,45,55],
    [65,75,76,86,87,88,98,99,100,101],
    [74,84,85,95,96,97,107,108,109,110],
    [111,112,113,114,115,116,117,118,119,120],
  ]
  BOARD_XY_TO_BOARD_INDEX_HASH = {}
  ALL_BOARD_XY.each_with_index{|s, bidx| BOARD_XY_TO_BOARD_INDEX_HASH[s] = bidx }
=begin
               #0(0,0)
                  X
                 X X
                X X X
#10(-4,8)      X X X X    #22(8,-4)
      X X X X X X X X X X X X X
       X X X X X X X X X X X X
        X X X X X X X X X X X
         X X X X X X X X X X
 #56(0,8) X X X X X X X X X #64(8,0)
         X X X X X X X X X X
        X X X X X X X X X X X
       X X X X X X X X X X X X
      X X X X X X X X X X X X X
#98(0,12)      X X X X    #110(12,0)
                X X X
                 X X
                  X
              #120(8,8)

=end
  def initialize(x, y, cell_distance, stone_size)
    @draw_attrs = {
      :x             => x,
      :y             => y,
      :cell_distance => cell_distance,
      :stone_size    => stone_size,
    }
  end
#------------------------------------------
#  cooridinate system
#------------------------------------------
  def board_xy_to_board_index(bx, by)
    return BOARD_XY_TO_BOARD_INDEX_HASH[[bx, by]]
  end
  def board_xy_to_real_xy(bx, by)
    rx = (bx - by) * DIVIDE_2 * @draw_attrs[:cell_distance]
    ry = (bx + by) * SQRT3_DIVIDE_2 * @draw_attrs[:cell_distance]
    return [rx, ry]
  end
  def real_xy_to_board_xy(rx, ry)
    x_minus_y = rx / (DIVIDE_2 * @draw_attrs[:cell_distance])
    x_plus_y = ry / (SQRT3_DIVIDE_2 * @draw_attrs[:cell_distance])
    bx = ((x_plus_y + x_minus_y) / 2.0).round
    by = ((x_plus_y - x_minus_y) / 2.0).round
    return [bx, by]
  end
  def window_xy_to_real_xy(wx, wy)
    rx = wx - @draw_attrs[:x]
    ry = wy - @draw_attrs[:y]
    return [rx, ry]
  end
#------------------------------------------
#  game control
#------------------------------------------
  def get_players_color(player_number, choose_color_idx) #get players' color
    idxs = case player_number
           when 2 ; [0, 3]
           when 3 ; [0, -2, 2]
           when 4 ; [0, 1, 3, 4]
           when 6 ; [0, 1, 2, 3, 4, 5, 6]
           else   ; raise("illegal player_number: #{player_number}")
           end
    return idxs.map{|s| (choose_color_idx + s) % 6 + 1}
  end
  def get_players_start_area(player_number) #get players' start area and goal
    aidxs = case player_number
            when 2 ; [5, 0]
            when 3 ; [5, 1, 2]
            when 4 ; [5, 4, 1, 0]
            when 6 ; [5, 4, 3, 2, 1, 0]
            else   ; raise("illegal player_number: #{player_number}")
            end
    return aidxs.map{|aidx|
      next {
        :start => ALL_PLAYER_START_AREA[aidx],
        :goal  => ALL_PLAYER_START_AREA[5 - aidx],
      }
    }
  end
  def start_game(player_number, choose_color_idx)
    @stones = ALL_BOARD_XY.map{|bx, by| Stone.new(bx, by, *board_xy_to_real_xy(bx, by), @draw_attrs[:stone_size]) }
    ALL_PLAYER_START_AREA.each{|array| array.each{|bidx| @stones[bidx].color_idx = 0 }} #set all area to gray color
    colors = get_players_color(player_number, choose_color_idx)
    areas = get_players_start_area(player_number)
    @players = Array.new(player_number){|idx|
      color = colors[idx]
      areas[idx][:start].each{|bidx| @stones[bidx].color_idx = color }
      ai = (idx == 0 ? AI_Manager.greedy_ai : nil)
      next Player.new(self, color, areas[idx][:goal], ai)
    }
    @game = Game.new(@players)
  end
#------------------------------------------
#  ACCESS
#------------------------------------------
  def get_stone_by_window_xy(wx, wy)
    return get_stone_by_board_xy(*real_xy_to_board_xy(*window_xy_to_real_xy(wx, wy)))
  end
  def get_stone_by_board_xy(bx, by)
    return get_stone_by_bidx(board_xy_to_board_index(bx, by))
  end
  def get_stone_by_bidx(bidx)
    return (bidx ? @stones[bidx] : nil)
  end
  def get_current_player_color
    return Stone::COLORS[@game.current_player.color_idx]
  end
#------------------------------------------
#  render
#------------------------------------------
  def update(window)
    @stones.each{|s| s.update }
    @game.update(window)
  end
  def draw(window)
    @font ||= Gosu::Font.new(window, Gosu::default_font_name, 24)
    @font.draw('Turn: ', 15, 48, BASE_ZIDX)
    window.draw_square(85, 60, 10, get_current_player_color.first, BASE_ZIDX)
    @stones.each{|s| s.draw(window, @draw_attrs[:x], @draw_attrs[:y]) }
    @game.draw(window)
  end

  def get_board_state_for_ai
    return @stones.map{|s| next (s.color_idx == nil ? 0 : s.color_idx) }
  end
#===================================
#  Game
#===================================
  class Game
    attr_reader :stones
    def initialize(players)
      @status = nil
      @players = players
      @player_number = players.size
      @current_player_idx = 0
    end
    def current_player
      return @players[@current_player_idx]
    end
#------------------------------------------
#  render
#------------------------------------------
    def update(window)
      return if @current_status != nil
      case self.current_player.update(window)
      when :next_turn
        @current_player_idx += 1
        @current_player_idx = 0 if @current_player_idx == @player_number
      when :fail #AI fail
        @current_status = :fail
      when :win
        @current_status = :win
      end
    end
    def draw(window)
      @font ||= Gosu::Font.new(window, Gosu::default_font_name, 24)
      case @current_status
      when :win
        @font.draw('win', 40, 70, BASE_ZIDX, 1.0, 1.0, 0xffffff00)
      when :fail
        @font.draw('fail', 40, 70, BASE_ZIDX, 1.0, 1.0, 0xffffff00)
      end
    end
  end
end
