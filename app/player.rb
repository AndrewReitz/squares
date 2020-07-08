# frozen_string_literal: true

# Player state class.
class Player
  attr_reader :loc_x, :loc_y, :direction, :rect, :solid, :safespace

  # Size of the player square.
  SIZE = 50

  # Offset for xy cordinates since this draws from center of square.
  HALF_SIZE = 25

  # Safe space offset for x and y values around the player
  # where enemies cannot spawn.
  SAFESPACE = SIZE * 3
  SAFESPACE_OFFSET = SAFESPACE / 2

  MIN_X = HALF_SIZE.freeze
  MAX_X = WIDTH - HALF_SIZE.freeze
  MIN_Y = HALF_SIZE.freeze
  MAX_Y = HEIGHT - HALF_SIZE.freeze

  COLOR = COLOR_WHITE.freeze

  def copy(x: nil, y: nil, direction: nil)
    x_actual = [[x || @loc_x, MIN_X].max, MAX_X].min
    y_actual = [[y || @loc_y, MIN_Y].max, MAX_Y].min

    Player.new(
      nil,
      x: x_actual,
      y: y_actual,
      direction: direction || @direction
    )
  end

  def initialize(player_state, x: nil, y: nil, direction: nil)
    @loc_x = x || player_state.x || WIDTH / 2
    @loc_y = y || player_state.y || HEIGHT / 2
    @direction = direction || player_state.direction || UP

    @rect = [@loc_x - HALF_SIZE, @loc_y - HALF_SIZE, SIZE, SIZE]
    @safespace = [@loc_x - SAFESPACE_OFFSET, @loc_y - SAFESPACE_OFFSET, SAFESPACE, SAFESPACE]
    @solid = @rect + COLOR

    freeze
  end

  def serialize(player)
    player.x = @loc_x
    player.y = @loc_y
    player.bullets = @bullets
    player.direction = @direction
  end
end
