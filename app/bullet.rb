# frozen_string_literal: true

# Bullet state class, state of bullets shot by the player.
class Bullet
  attr_reader :loc_x, :loc_y, :direction, :rect, :solid

  SIZE = 10
  HALF_SIZE = 5
  VELOCITY = 10

  COLOR = COLOR_WHITE.freeze

  def initialize(bullet, x: nil, y: nil, direction: nil)
    @loc_x = x || bullet.x
    @loc_y = y || bullet.y
    @direction = direction || bullet.direction

    @rect = [@loc_x - HALF_SIZE, @loc_y - HALF_SIZE, SIZE, SIZE]
    @solid = @rect + COLOR
    freeze
  end

  def copy(x:, y:)
    Bullet.new(self, x: x, y: y)
  end

  def serialize(bullet)
    bullet.x = @loc_x
    bullet.y = @loc_y
    bullet.direction = @direction
  end
end
