#!/usr/bin/ruby
require 'camping'
require 'camping/session'
require 'pusher'
require 'erb'
require 'securerandom'
require_relative 'boggle_solver'
require_relative 'boggle_board_generator'
require 'json'
Camping.goes :Pb
  
module Pb 
    # Path to where you want to store the templates 
    # set :views, File.dirname(__FILE__) + '/views' 

     # secret
    environment = ENV['DATABASE_URL'] ? 'production' : 'development'
    configsession = 'config/session'
    if File.exists?(configsession)
        secret = File.read(configsession)
    else
        secret = SecureRandom.hex 
        if environment == 'development'
            File.open(configsession, 'w') {|f| f.write(secret) }
        end
    end   
    set :secret, secret
    include Camping::Session   
end 

module Pb::Models
      class Game < Base
        serialize :solutions, Array
        serialize :guesses, Array
      end

      class GameFields < V 1.0
        def self.up
          create_table Game.table_name do |t|
          t.text   :board
          t.text   :solutions
          t.text   :guesses
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
          t.integer :score, :default => 0
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
        require './config/pusher.rb'
    end
    dictionary = 'boggle.dict'
    puts "importing dictionary #{dictionary} (this takes a few seconds)"
    $solver = BoggleSolver::Solver.new(dictionary)
    puts $solver
end
 
module Pb::Controllers
  class Index
    def get
          requires_login!
          @games = Game.all(:order=>"updated_at DESC",:limit=>3) 
          @users = User.all(:order=>"score DESC", :limit=>3)
          render :home
    end
  end

    class PusherAuth
        def post
             if logged_in? and @input.include?('channel_name') and @input.include?('socket_id') 
              auth = Pusher[@input.channel_name].authenticate(@input.socket_id,:user_id => @state.user_id , :user_info => {:name => @state.user_name} )
                @headers['Content-Type'] = 'text/plain' # 'application/json' # technically correct
                auth.to_json
            else
              @status = 403
              @headers['Content-Type'] = 'text/plain'
              "Not authorized"
            end
        end
    end

    class Login
        def get
            if logged_in?
                redirect Index
            end
            render :login
        end

        def post
            @input.user.strip!
            unless @input.user.empty?
                u = User.find_or_create_by_name(@input.user)
                @state.user_name = @input.user
                @state.user_id = u.id
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
        def get(id)
            requires_login!
            @id = id
            @g = Game.find_by_id(id)
            unless @g
                @status = 404
                "no game with id #{id}"
            else
                render :game
            end
        end

        def post(id)
            requires_login!
            u = User.find(@state.user_id)
            g = Game.find(id)
            @input.guess.downcase!
            correct = ( g.solutions.include?(@input.guess) ) 
            if correct
                unless g.guesses.include?(@input.guess)
                    g.guesses << @input.guess
                    g.save
                    u.score += @input.guess.length
                    u.save
                end
            end
            redirect R(GameX,id)
        end
    end

    class New
        def get
            requires_login!
            board = BoggleBoardGenerator.new
            solutions = $solver.solve(board.board_2d)
            g = Game.create(:board=>board, :solutions => solutions, :guesses => [])
            redirect R(GameX,g.id)
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
      unless logged_in?
        redirect Pb::Controllers::Login     # ugh, make this less explicit
        throw :halt
      end
    end

    def logged_in?
        @state.key?('user_id')
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
      body do
        text ' <a href="https://github.com/matt-hickford/placeboxy"><img style="position: absolute; top: 0; right: 0; border: 0;" src="https://assets1.github.com/img/71eeaab9d563c2b3c590319b398dd35683265e85?repo=&url=http%3A%2F%2Fs3.amazonaws.com%2Fgithub%2Fribbons%2Fforkme_right_gray_6d6d6d.png&path=" alt="Fork me on GitHub"></a> '
            h1 "Placeboxy"
            self << yield

            p.connected! "not connected"
            if logged_in?
                p do
                    a "logout", :href=>R(Logout)
                    text " (you are #{@state.user_name})" 
                end
            end
          end
      end
    end

    def home
        p do
            a "new game", :href => R(New)
        end

        h2 "Recent games"
        ul do
            @games.each do |game|
                li { a game.id, :href => R(GameX,game.id) }
            end
        end

        h2 "Top scoring players"
        ul do
            @users.each do |user|
                li "#{user.name} #{user.score}" 
            end
        end

        h2 "Players on this page"
        ul.users! {}    

    end

    def login
            form.login! :action => R(Login), :method => :post do
                p "To play, I need your name"
                input.input! "", :type => "text", "name" => :user
                input :type => :submit, :value => "login"
            end
    end

  def game
        h2 "Game #{@g.id}"
        textarea.board @g.board.to_s , "rows"=>"4"
        # p.solutions @g.solutions.join(",")

        form.form! :action => R(GameX,@g.id), :method => :post do
          input.input! "", :type => "text", :name => :guess
            br
          input :type => :submit, :value => "guess!"
        end

        ul.guesses do
            @g.guesses.each do |guess|
                li guess
            end
        end

        p { a "home", :href=>R(Index) }
  end
end


