#!/usr/bin/ruby
require 'camping'

require 'boggle_solver'
puts "loading Boggle solver.."
$solver = BoggleSolver::Solver.new("boggle.dict")
puts $solver

Camping.goes :Pb

module Pb::Models
  class Game < Base
    serialize :solutions
  end
  
  class BasicFields < V 1.0
    def self.up
      create_table Game.table_name do |t|
      t.string :name
      t.text   :board
      t.text   :solutions
      # This gives us created_at and updated_at
      t.timestamps
      end
    end

    def self.down
      drop_table Game.table_name
    end
  end
end

def Pb.create
  Pb::Models.create_schema
end

module Pb::Controllers
  class Index
    def get
      require 'active_support/secure_random'
      @name = ActiveSupport::SecureRandom.hex
      render :home
    end
  end

    class GameX
        def get(name)
            @g = Game.find_by_name(name)
            if not @g
                require 'boggle_board_generator'
                board = BoggleBoardGenerator.new

                #y = board.to_input_s.split(//).map { |l| l == 'q' ? 'qu' : l }.enum_slice(4).to_a
                #solutions = [] #BoggleServer.server_solve(y)
                solutions = $solver.solve(board.board_2d)
                @g = Game.create(:name=>name, :board=>board, :solutions => solutions)
            end
            render :game
        end

        def post(name)
            @g = Game.find_by_name(name)
            @input.guess
            "%s" % ( @g.solutions.include?(@input.guess) ) 
        end
    end
end

module Pb::Views
  def layout
    html do
      head do
        title "Placeboxy"
        #link :rel => 'stylesheet',:type => 'text/css',:href => '/styles.css'
        script "", :type => 'text/javascript', :src => 'https://ajax.googleapis.com/ajax/libs/jquery/1.4.4/jquery.min.js'
      end
      body { self << yield }
    end
    p do
        a "home", :href=>R(Index)
    end
  end

    def home
        h1 "Placeboxy"
        p do
            a "new game", :href => R(GameX, @name)
        end
    end

  def game
        p.name @g.name
        textarea.board @g.board.to_s , "rows"=>"4"
        p.solutions @g.solutions.join(",")

        form :action => R(GameX,@g.name), :method => :post do
          input "", :type => "text", :name => :guess
            br
          input :type => :submit, :value => "guess!"
        end

  end
end


