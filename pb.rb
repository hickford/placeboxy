#!/usr/bin/ruby
require 'camping'
require 'pusher'
require 'erb'
require 'active_support/secure_random'
require 'boggle_solver'
require 'boggle_board_generator'

Camping.goes :Pb

module Pb::Models
  class Game < Base
    serialize :solutions, Array
    serialize :guesses, Array
  end
  
  class BasicFields < V 1.0
    def self.up
      create_table Game.table_name do |t|
      t.string :name
      t.text   :board
      t.text   :solutions
      t.text    :guesses
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

    environment = ENV['DATABASE_URL'] ? 'production' : 'development'
    if environment == 'development'
        # Pusher.app_id , Pusher.key , Pusher.secret
        require './config/pusher/development.rb'
    end

    dictionary = (environment == 'production') ? 'boggle.dict' : 'short.dict'
    puts "importing dictionary %s (this may take some time)" % dictionary
    $solver = BoggleSolver::Solver.new(dictionary)
    puts $solver
end

module Pb::Controllers
  class Index
    def get

      @name = ActiveSupport::SecureRandom.hex
      render :home
    end
  end

    class GameX
        def get(name)
            @name = name
            @g = Game.find_by_name(name)
            if not @g

                board = BoggleBoardGenerator.new
                solutions = $solver.solve(board.board_2d)
                @g = Game.create(:name=>name, :board=>board, :solutions => solutions, :guesses => [])
            end
            render :game
        end

        def post(name)
            @g = Game.find_by_name(name)
            correct= ( @g.solutions.include?(@input.guess) ) 

            if correct
                @g.guesses << @input.guess
                @g.save
            end
            redirect R(GameX,name)

        end
    end

  class Js < R '/pb.js'
    def get
        @headers['Content-Type'] = 'text/javascript'
        ERB.new(File.read('pb.js')).result
    end
  end
end

module Pb 
    # Path to where you want to store the templates 
    set :views, File.dirname(__FILE__) + '/views' 
end 

module Pb::Views
  def layout
    html do
      head do
        title "Placeboxy"
        #link :rel => 'stylesheet',:type => 'text/css',:href => '/styles.css'
        script "", :type => 'text/javascript', :src => 'https://ajax.googleapis.com/ajax/libs/jquery/1.4.4/jquery.min.js'
        script "", :type => 'text/javascript', :src => 'http://js.pusherapp.com/1.6/pusher.min.js'
        script "", :type => 'text/javascript', :src => '/pb.js'
      end
      body { self << yield }
    end
    p.connected! "not connected"
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

        form.form! :action => R(GameX,@g.name), :method => :post do
          input.guess! "", :type => "text", :name => :guess
            br
          input :type => :submit, :value => "guess!"
        end

        ul.guesses do
            @g.guesses.each do |guess|
                li guess
            end
        end

  end
end


