# frozen_string_literal: true

# State of of an Enemy square.
class Enemy
  attr_accessor :loc_x, :loc_y, :rect, :solid

  SPEED = 2
  SIZE = 20
  HALF_SIZE = SIZE / 2

  COLOR = COLOR_RED

  def self.random
    Enemy.new(nil, x: rand(WIDTH), y: rand(HEIGHT))
  end

  def initialize(enemy, x: nil, y: nil)
    @loc_x = x || enemy.x
    @loc_y = y || enemy.y

    @rect = [@loc_x - HALF_SIZE, @loc_y - HALF_SIZE, SIZE, SIZE]
    @solid = @rect + COLOR

    freeze
  end

  def serialize(enemy)
    enemy.x = @loc_x
    enemy.y = @loc_y
  end
end
