HEIGHT = 720
WIDTH = 1280

UP = 1
LEFT = 2
DOWN = 3
RIGHT = 4

class Enemy

  SPEED = 1
  SIZE = 20
  HALF_SIZE = SIZE / 2

  def initialize(x, y)
    @x = x
    @y = y
  end

  def draw(args, player)
    args.outputs.solids << [x - HALF_SIZE, y - HALF_SIZE, SIZE, SIZE, 255, 0, 0]

    if args.state.lose
      return
    end
    
    if player.x > @x
      @x += SPEED
    end
    if player.x < @x
      @x -= SPEED
    end
    if player.y > @y
      @y += SPEED
    end
    if player.y < @y
      @y -= SPEED
    end
  end

  def serialize
    { 
      x: @x, 
      y: @y
    }
  end

  def y
    @y
  end

  def x
    @x
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end

  def intersects(player)
    [x - HALF_SIZE, y - HALF_SIZE, SIZE, SIZE].intersect_rect? [player.x - Player::HALF_SIZE, player.y - Player::HALF_SIZE, Player::SIZE, Player::SIZE]
  end
end

class Player

  SIZE = 50
  HALF_SIZE = 25

  def initialize(x = WIDTH / 2, y = HEIGHT / 2)
    @x = x
    @y = y
    @direction = UP
    @bullets = []
  end

  def draw args
    args.outputs.solids << [x - HALF_SIZE, y - HALF_SIZE, SIZE, SIZE, 255, 255, 255]

    if args.state.lose
      return
    end

    if args.inputs.keyboard.key_held.a
      @direction = LEFT
      @x -= 5
      @x = [@x, 0 + 25].max
    end
    if args.inputs.keyboard.key_held.d
      @direction = RIGHT
      @x += 5
      @x = [@x, WIDTH - 25].min
    end
    if args.inputs.keyboard.key_held.w
      @direction = UP
      @y += 5
      @y = [@y, HEIGHT - 25].min
    end
    if args.inputs.keyboard.key_held.s
      @direction = DOWN
      @y -= 5
      @y = [@y, 0 + 25].max
    end

    if args.inputs.keyboard.key_down.space
      @bullets << Bullet.new(@x, @y, @direction)
    end

    toRemove = []
    @bullets.each do |bullet|
      bullet.draw(args)
      if bullet.x < 0 || bullet.x > WIDTH || bullet.y < 0 || bullet.y > HEIGHT
        toRemove << bullet
      end
    end
    toRemove.each do |b|
      @bullets.delete(b)
    end
  end

  def x
    @x
  end

  def y
    @y
  end

  def direction
    @direction
  end

  def bullets
    @bullets
  end

  def serialize
    { 
      x: @x, 
      y: @y, 
      direction: @direction,
      bullets: @bullets
    }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end
end

class Bullet

  SIZE = 10
  HALF_SIZE = 5
  VELOCITY = 10

  def initialize(x, y, direction)
    @x = x
    @y = y
    @direction = direction
  end

  def draw args
    if (@direction == UP)
      @y += VELOCITY
    end
    if (@direction == DOWN)
      @y -= VELOCITY
    end
    if (@direction == LEFT)
      @x -= VELOCITY
    end
    if (@direction == RIGHT)
      @x += VELOCITY
    end

    args.outputs.solids << [@x - 5, @y - 5, SIZE, SIZE, 255, 255, 255]
  end

  def x
    @x
  end

  def y
    @y
  end

  def direction
    @direction
  end

  def serialize
    { 
      x: @x, 
      y: @y, 
      direction: @direction
    }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end

  def intersects(enemy)
    [@x - 5, @y - 5, SIZE, SIZE].intersect_rect? [enemy.x - Enemy::HALF_SIZE, enemy.y - Enemy::HALF_SIZE, Enemy::SIZE, Enemy::SIZE]
  end
end

def tick args
  args.state.enemy.count ||= 2
  args.state.score ||= 0
  args.state.lose ||= false
  args.outputs.solids << [0, 0, WIDTH, HEIGHT]
  args.state.player ||= Player.new
  player = args.state.player
  player.draw(args)

  do_enemy_things args

  args.outputs.labels << [
    WIDTH - 200, HEIGHT - 10, "Score #{args.state.score}", 255, 255, 255
  ]
end

def do_enemy_things args
  args.state.enemies ||= [ Enemy.new(0, 0), Enemy.new(WIDTH, HEIGHT) ]
  
  player = args.state.player
  enemies = args.state.enemies

  enemies.each do |e|
    player.bullets.each do |b|
      if b.intersects(e)
        args.state.score += 1
        enemies.delete(e)
      end
    end

    e.draw(args, player)
    if e.intersects(player)
      args.state.lose = true
      args.outputs.labels << [
        x: WIDTH / 2 - 25, 
        y: HEIGHT / 2, 
        text: "Game Over", 
        size_enum: 2,
        alignment_enum: 0, 
        r: 255
      ]
    end
  end

  if args.state.enemies.length == 0
    args.state.enemy.count *= 2
    args.state.enemies += args.state.enemy.count.map do
      enemy = Enemy.new(rand(WIDTH), rand(HEIGHT))
      while enemy.intersects(player)
        enemy = Enemy.new(rand(WIDTH), rand(HEIGHT))
      end
      enemy
    end
  end
end

def r
  $gtk.reset 0
end
