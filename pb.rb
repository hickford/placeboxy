#!/usr/bin/ruby
require 'camping'
require 'camping/session'
require 'pusher'
require 'erb'
require 'active_support/secure_random'
require 'boggle_solver'
require 'boggle_board_generator'

Camping.goes :Pb

module Pb 
    # Path to where you want to store the templates 
    set :views, File.dirname(__FILE__) + '/views' 
end 

module Pb::Models
      class Game < Base
        serialize :solutions, Array
        serialize :guesses, Array
      end

      class GameFields < V 1.0
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

        class User < Base
        end

      class UserFields < V 1.1
        def self.up
          create_table User.table_name do |t|
          t.string :name
          t.integer :score
          # This gives us created_at and updated_at
          t.timestamps
          end
         end

            def self.down
               drop_table User.table_name
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

    # secret
    configsession = 'config/session'
    if File.exists?(configsession)
        secret = File.read(configsession)
    else
        secret = ActiveSupport::SecureRandom.hex 
        File.open(configsession, 'w') {|f| f.write(secret) }
    end   
    set :secret, secret
    include Camping::Session   

    dictionary = (environment == 'production') ? 'boggle.dict' : 'short.dict'
    puts "importing dictionary %s (this takes a few seconds)" % dictionary
    $solver = BoggleSolver::Solver.new(dictionary)
    puts $solver
end

module Pb::Controllers
  class Index
    def get
          requires_login!
          @games = Game.all(:order=>"updated_at DESC",:limit=>3) 
          render :home
    end
  end

    class PusherAuth
        def get
             if @state.user
              auth = Pusher[@input.channel_name].authenticate(@input.socket_id, :user_id => @state.user)
              #render :json => auth
              # broken
              
            else
              @status = 403
              "Not authorized"
            end

        end
    end

    class Login
        def get
            render :login
        end

        def post
            @input.user.strip!
            unless @input.user.empty?
                @state.user = @input.user
            end
            redirect Index
        end
    end

    class Logout
        def get
            @state.clear
            redirect Index
        end
    end

    class GameX
        def get(name)
            requires_login!
            @name = name
            @g = Game.find_by_name(name)
            unless @g
                board = BoggleBoardGenerator.new
                solutions = $solver.solve(board.board_2d)
                @g = Game.create(:name=>name, :board=>board, :solutions => solutions, :guesses => [])
            end
            render :game
        end

        def post(name)
            requires_login!
            @g = Game.find_by_name(name)
            @input.guess.downcase!
            correct= ( @g.solutions.include?(@input.guess) ) 

            if correct
                @g.guesses << @input.guess
                @g.save
            end
            redirect R(GameX,name)

        end
    end

    class New
        def get
            requires_login!
            redirect R(GameX, ActiveSupport::SecureRandom.hex )
        end
    end


  class Js < R '/pb.js'
    def get
        @headers['Content-Type'] = 'text/javascript'
        ERB.new(File.read('pb.js')).result
    end
  end
end

  module Pb::Helpers
    def requires_login!
      unless @state.user
        redirect Pb::Controllers::Login     # ugh, make this less explicit
        throw :halt
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
        script "", :type => 'text/javascript', :src => 'http://js.pusherapp.com/1.6/pusher.min.js'
        script "", :type => 'text/javascript', :src => '/pb.js'
      end
        text ' <a href="https://github.com/matt-hickford/placeboxy"><img style="position: absolute; top: 0; right: 0; border: 0;" src="https://assets1.github.com/img/71eeaab9d563c2b3c590319b398dd35683265e85?repo=&url=http%3A%2F%2Fs3.amazonaws.com%2Fgithub%2Fribbons%2Fforkme_right_gray_6d6d6d.png&path=" alt="Fork me on GitHub"></a> '
      body do
            h1 "Placeboxy"
            self << yield
            p.connected! "not connected"
            if @state.user
                p do
                    a "logout", :href=>R(Logout)
                    text " (you are %s)" % @state.user
                end
            end
            p do
                a "home", :href=>R(Index)
            end
          end
      end
    end

    def home
        p "Hello %s" % @state.user
        p do
            a "new game", :href => R(New)
        end
        h2 "Recent games"
        ul do
            @games.each do |game|
                li do
                    a game.name, :href => R(GameX,game.name)
                end
            end
        end
    end

    def login
            form.login! :action => R(Login), :method => :post do
                p "To play, I need your name"
                input.input! "", :type => "text", "name" => :user
                input :type => :submit, :value => "login"
            end
    end

  def game
        p.name @g.name
        textarea.board @g.board.to_s , "rows"=>"4"
        p.solutions @g.solutions.join(",")

        form.form! :action => R(GameX,@g.name), :method => :post do
          input.input! "", :type => "text", :name => :guess
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


