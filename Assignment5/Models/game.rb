require '../Models/disc.rb'
require '../Models/computer.rb'
require '../Views/game_view.rb'
#require '../contracts.rb'
require 'singleton'
require 'observer'
require 'matrix'
require 'xmlrpc/client'

class Game
  include Singleton
  include Observable
  include Computer
  #include Contracts
  attr_accessor :type, :state, :currentTurn, :pTurn
  attr_reader :players

  def newGame(type, gview, p1, p2)
    @pTurn = [p1, p2]
    if type == 'otto'
      @players=['o','t']
    else
      @players=['red','blue']
    end
    @type = type
    @state = Matrix.build(6,7) {Disc.new()}
    @currentTurn = 0
    @view = gview
    @server = XMLRPC::Client.new(ENV['HOSTNAME'], "/RPC2", 50525)
  end

  def newGameS(type, gview, p1, p2)
    @pTurn = [p1, p2]
    if type == 'otto'
      @players=['o','t']
    else
      @players=['red','blue']
    end
    @type = type
    @state = Matrix.build(6,7) {Disc.new()}
    @view = gview
    @server = XMLRPC::Client.new(ENV['HOSTNAME'], "/RPC2", 50525)
    @game_id, @currentTurn = @server.call('move.createGame', p1.name, type)
    if (@currentTurn == 1)
      gview['message'].text = "game created"
    else
      gview['message'].text = "game joined"
    end
    puts @game_id
    puts @currentTurn
  end

  def loadGame(type, gview, p1, p2, state = nil)
    @server = XMLRPC::Client.new(ENV['HOSTNAME'], "/RPC2", 50525)
    @pTurn = [p1, p2]
    if type == 'otto'
      @players=['o','t']
    else
      @players=['red','blue']
    end
    @type = type
    @state = state
    @currentTurn = 0
    @view = gview
  end

  def updateViews(val = false)
    @view.update(val)
  end

  def recvMove(player)
    return @server.call('move.recvMove', @game_id)
  end

  #will only make the move if its the players turn
  def makeMove(move, player)
    #Contracts.makeMove_pre(player, move, self)
    placed = nil

    if (@server.call('move.game_end', @game_id) != -1)
      @view['message'].text = "Game has ended"
      return false
    end

    if (@pTurn[currentTurn].type == 'server_human')
      move = recvMove(@pTurn[currentTurn]).to_i
      player = @pTurn[currentTurn]
    end

    puts player.type
    puts @pTurn[currentTurn].eql? player
    puts @game_id
    puts move

    if((@pTurn[currentTurn].eql? player) && (move != -1))
      puts 'here'
      placed = false

      for i in 0..5
        if(@state.element(5-i,move).type == 'empty')
          @server.call('move.makeMove', @game_id, player.name, move)
          @view['message'].text = "Move made"
          @state.element(5-i,move).type = players[currentTurn]
          placed = true

          if(draw())
            @view['message'].text = "Game is draw"
            puts "Game is draw"
            @server.call('move.game_over', 0)
            #updateViews(true)
            #TODO end game here somehow
            return true
          end

          if(win(5-i, move, currentTurn))
            @server.call('move.game_over', 1, player)
            @view['message'].text = "Player #{currentTurn+1} wins"
            puts "Player #{currentTurn+1} wins"
            #updateViews(true)
            #TODO end game here somehow
            return true
          end

          self.currentTurn = (currentTurn + 1) %2

          #makes computer move, there should be a better way to do this...
          if (@pTurn[currentTurn].type != 'human' && @pTurn[currentTurn].type != 'server_human')
            if (@pTurn[currentTurn].type != 'bot_easy')
              level = 0
            else
              level = 1
            end
            makeMove(Computer.makeMove(level, self, @pTurn[currentTurn]), @pTurn[currentTurn])
            if(win(5-i, move, currentTurn))
              @view['message'].text = "Player #{currentTurn+1} wins"
              puts "Player #{currentTurn+1} wins"
              updateViews(true)
              #TODO end game here somehow
              return true
            end
          end
          ###

          break
        end
      end

      puts 'here'

      if placed == false
        puts 'no room in column'
      else 
        updateViews()
        return true
      end
    end
    
    return false
  end

  def draw()
    @state.row_vectors.each do |r|
      r.to_a.each do |e|
        if (e.type == 'empty')
          return false
        end
      end
    end
    return true
  end


  def win(rows, cols, currentTurn)
    if (@type == 'otto') 
      #check rows for win
      val = ""
      @state.row(rows).each do |p|
        val = val + p.type
      end
      
      if (val.include? "otto" )|| (val.include? "toot")
        return true
      end
    
      #check columns for win
      val = ""
      @state.column(cols).each do |p|
        val = val + p.type
      end

      if (val.include? "otto") || (val.include? "toot")
        return true
      end

      #check diagonals for win
      val = ""
      total = rows + cols
      if (total < 9 && total > 2)
        for c in 0..6
          if (total - c) >= 0 && (total + c) < 6
            val = val + @state.element(total-c, c).type
          end          
        end
      end

      if (val.include? "otto") || (val.include? "toot")
        return true
      end
    
      count = 0
      total = (rows - cols).abs
      if total < 4
        for c in 0..6
          if (total + c) < 6
            val = val + @state.element(total+c, c).type
          end
        end
      end
     
      if (val.include? "otto") || (val.include? "toot")
        return true
      end

      return false

    else

      count = 0

      #check rows for win
      @state.row(rows).each do |p|
        if p.type == players[currentTurn]
          count = count + 1
        else
          count = 0
        end
        if count == 4
          return true
        end
      end
    
      #check columns for win
      count = 0
      @state.column(cols).each do |p|
        if p.type == players[currentTurn]
          count = count + 1
        else
          count = 0
        end
        if count == 4
          return true
        end
      end

      #check diagonals for win
      count = 0
      total = rows + cols
      if (total < 9) && (total > 2)
        for c in 0..6
          if (total - c) >= 0 && (total + c) < 6
            if @state.element(total-c, c).type == players[currentTurn]
              count = count + 1
            else
              count = 0
            end
            if count == 4
              return true
            end
          end
        end
      end
    
      count = 0
      total = (rows - cols).abs
      if total < 4
        for c in 0..6
          if (total + c) < 6
            if @state.element(total+c, c).type == players[currentTurn]
              count = count + 1
            else
              count = 0
            end
            if count == 4
              return true
            end
          end          
        end
      end

      return false
    end
  end

end
