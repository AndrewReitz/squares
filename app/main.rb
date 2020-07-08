# frozen_string_literal: true

$gtk.require('app/player.rb')
$gtk.require('app/enemy.rb')
$gtk.require('app/bullet.rb')
$gtk.require('app/game_state.rb')

HEIGHT = 720
WIDTH = 1280

UP = 1
LEFT = 2
DOWN = 3
RIGHT = 4

ENTIRE_SCREEN_RECT = [0, 0, WIDTH, HEIGHT].freeze
COLOR_BLACK = [0, 0, 0].freeze
COLOR_WHITE = [255, 255, 255].freeze
COLOR_RED = [255, 0, 0].freeze

DEBUG = false

def log(args)
  puts args if DEBUG
end

def keyboard
  $args.inputs.keyboard
end

def controller
  $args.inputs.controller_one
end

def mouse
  $args.inputs.mouse
end

def solids
  $args.outputs.solids
end

def labels
  $args.outputs.labels
end

def borders
  $args.outputs.borders
end

def draw_button(x:, y:, text:, game_state: game_state, &onclick)
  w = 300
  h = 50
  $args.state.buttons ||= {}

  clicked_at = $args.state.buttons[text]

  border = [x - w.half, y - h.half, w, h, 255, 0, 0]

  $args.state.buttons[text] = $args.tick_count if mouse.click&.point&.inside_rect?(border)

  if !clicked_at.nil? && clicked_at + 0.25.seconds < $args.tick_count
    game_state = onclick.call game_state
    $args.state.buttons[text] = nil
  end

  labels << [x, y + 10, text, 0, 1, 255, 0, 0]
  borders << border
  solids << border + [255 * clicked_at&.ease(0.25.seconds, :flip) || 1]

  game_state
end

def tick(args)
  $args = args

  game_state = GameState.new(args)

  # Update
  case game_state.state
  when :start
    labels << [$args.grid.w_half, $args.grid.h_half, 'Press any key to start', 3, 1, 255, 255, 255]
    if mouse.click || keyboard.directional_vector || keyboard.key_down.enter || keyboard.key_down.escape
      game_state = game_state.copy(state: :playing)
    end
  when :playing
    game_state = move_player(game_state)
    game_state = move_enemies(game_state)
    game_state = player_shooting?(game_state)
    game_state = move_bullets(game_state)
    game_state = bullet_enemy_collision(game_state)
    game_state = enemy_player_collision(game_state)
    game_state = create_more_enemies(game_state)
  end

  # Draw
  draw_debug
  draw_background

  if game_state.state == :playing || game_state.state == :game_over
    draw_player(game_state)
    draw_bullets(game_state)
    draw_enemies(game_state)
    draw_score(game_state)
  end

  if game_state.state == :game_over
    if game_state.game_over_at + 1.seconds < $args.tick_count
      game_state = draw_button(
        x: $args.grid.w_half, 
        y: $args.grid.h_half, 
        text: 'Try Again?', 
        game_state: game_state
      ) do |g|
        new_game = g.reset
        new_game.copy(state: :playing)
      end
    elsif labels << [$args.grid.w_half, $args.grid.h_half, 'Game Over', 3, 1, 255, 255, 255]
    end
  end

  game_state.serialize
end

# Draw debug things if DEBUG flag is set to true.
def draw_debug
  return unless DEBUG

  args.outputs.borders << game_state.player.safespace + COLOR_RED
end

def move_player(game_state)
  x = game_state.player.loc_x
  y = game_state.player.loc_y
  direction = game_state.player.direction

  if keyboard.key_held.a || controller.key_held.left || keyboard.left
    direction = LEFT
    x -= 5
  end
  if keyboard.key_held.d || controller.key_held.right || keyboard.right
    direction = RIGHT
    x += 5
  end
  if keyboard.key_held.w || controller.key_held.up || keyboard.up
    direction = UP
    y += 5
  end
  if keyboard.key_held.s || controller.key_held.down || keyboard.down
    direction = DOWN
    y -= 5
  end

  player = game_state.player.copy(x: x, y: y, direction: direction)
  game_state.copy(player: player)
end

def draw_background
  solids << ENTIRE_SCREEN_RECT + COLOR_BLACK
end

def draw_player(game_state)
  solids << game_state.player.solid
end

def draw_bullets(game_state)
  solids << game_state.bullets.map(&:solid)
end

def draw_enemies(game_state)
  game_state.enemies.map do |e|
    solids << e.solid
  end
end

def draw_score(game_state)
  labels << [10, HEIGHT - 10, "Score: #{game_state.score}", 1, 0, 255, 0, 0]
end

def create_more_enemies(game_state)
  return game_state if game_state.enemies?

  enemy_count = game_state.enemy_count * 2

  if enemy_count == 4
    enemies = [
      Enemy.new(nil, x: $args.grid.left, y: $args.grid.top),
      Enemy.new(nil, x: $args.grid.right, y: $args.grid.bottom),
      Enemy.new(nil, x: $args.grid.left, y: $args.grid.bottom),
      Enemy.new(nil, x: $args.grid.right, y: $args.grid.top)
    ]

    return game_state.copy(enemies: enemies, enemy_count: enemy_count)
  end

  player_area = game_state.player.safespace

  enemies = enemy_count.map do |_|
    e = Enemy.random
    e = Enemy.random while e.rect.intersect_rect?(player_area)
    e
  end

  game_state.copy(enemies: enemies, enemy_count: enemy_count)
end

def player_shooting?(game_state)
  player = game_state.player

  if keyboard.key_down.space || controller.key_down.x ||
     controller.key_down.y || controller.key_down.a ||
     controller.key_down.b || mouse.click
    b = Bullet.new(
      nil,
      x: player.loc_x,
      y: player.loc_y,
      direction: player.direction
    )
    return game_state.copy(bullets: game_state.bullets + [b])
  end

  game_state
end

def move_bullets(game_state)
  new_bullets = game_state.bullets.map do |b|
    new_x = b.loc_x
    new_y = b.loc_y
    if b.direction == UP
      new_y += Bullet::VELOCITY
    elsif b.direction == DOWN
      new_y -= Bullet::VELOCITY
    elsif b.direction == LEFT
      new_x -= Bullet::VELOCITY
    elsif b.direction == RIGHT
      new_x += Bullet::VELOCITY
    end

    b.copy(x: new_x, y: new_y)
  end

  new_bullets = new_bullets.select do |b|
    b.loc_x < WIDTH && b.loc_x.positive? && b.loc_y.positive? && b.loc_y < HEIGHT
  end

  game_state.copy(bullets: new_bullets)
end

def move_enemies(game_state)
  player = game_state.player

  new_enemies = game_state.enemies.map do |e|
    new_x = e.loc_x
    new_y = e.loc_y
    if player.loc_x < e.loc_x
      new_x -= Enemy::SPEED
    elsif player.loc_x > e.loc_x
      new_x += Enemy::SPEED
    end

    if player.loc_y < e.loc_y
      new_y -= Enemy::SPEED
    elsif player.loc_y > e.loc_y
      new_y += Enemy::SPEED
    end

    Enemy.new(nil, x: new_x, y: new_y)
  end

  game_state.copy(enemies: new_enemies)
end

def bullet_enemy_collision(game_state)
  enemies_to_remove = []

  game_state.bullets.each do |b|
    game_state.enemies.each do |e|
      enemies_to_remove << e if b.rect.intersect_rect?(e.rect)
    end
  end

  score = game_state.score + enemies_to_remove.size

  new_enemies = game_state.enemies.reject do |e|
    enemies_to_remove.include?(e)
  end

  game_state.copy(enemies: new_enemies, score: score)
end

def enemy_player_collision(game_state)
  found = game_state.enemies.find { |e| e.rect.intersect_rect?(game_state.player.rect) }

  return game_state.copy(state: :game_over) if found

  game_state
end

def r
  $gtk.reset 0
end
