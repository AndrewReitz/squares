# frozen_string_literal: true

# State of the game.
# state: :start, :playing, :game_over
class GameState
  attr_reader :player, :enemies, :score, :bullets, :enemy_count, :state, :game_over_at

  def reset()
    @args.state.score = nil
    @args.state.player = nil
    @args.state.enemies = nil
    @args.state.bullets = nil
    @args.state.enemy_count = nil
    @args.state.state = nil
    @args.state.game_over_at = nil
    GameState.new(@args)
  end

  def copy(player: nil, enemies: nil, score: nil, bullets: nil, enemy_count: nil, state: nil)
    GameState.new(
      @args,
      player: player || @player,
      enemies: enemies || @enemies,
      score: score || @score,
      bullets: bullets || @bullets,
      enemy_count: enemy_count || @enemy_count,
      state: state || @state
    )
  end

  def initialize(args, player: nil, enemies: nil, score: nil, bullets: nil, enemy_count: nil, state: nil)
    @args = args

    @player = player || Player.new(args.state.player || args.state.new_entity(:player))

    log "args.state.enemies #{args.state.enemies}"

    unless args.state.enemies
      enemies = [
        Enemy.new(nil, x: args.grid.left, y: args.grid.top),
        Enemy.new(nil, x: args.grid.right, y: args.grid.bottom)
      ]
    end
    @enemies = enemies || args.state.enemies.map { |e| Enemy.new(e) }
    @enemy_count = enemy_count || args.state.enemy_count || 2

    @score = score || args.state.score || 0

    log "args.state.bullets #{args.state.bullets}"
    args.state.bullets ||= []
    @bullets = bullets || args.state.bullets.map { |b| Bullet.new(b) }

    @state = state || args.state.state || :start

    @game_over_at = game_over_at || args.state.game_over_at || 0

    freeze
  end

  def enemies?
    !@enemies.empty?
  end

  def serialize
    @args.state.score = @score

    @player.serialize(@args.state.player)

    @args.state.enemies = @enemies.map do |e|
      enemy = @args.state.new_entity(:enemy)
      e.serialize(enemy)
      enemy
    end

    @args.state.bullets = @bullets.map do |b|
      bullet = @args.state.new_entity(:bullet)
      b.serialize(bullet)
      bullet
    end

    @args.state.enemy_count = @enemy_count

    @args.state.state = @state

    @args.state.game_over_at = @game_over_at
  end
end
