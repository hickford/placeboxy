#!/usr/bin/env ruby
require 'trie'
require 'set'


# The BoggleSolver class is used to solve Boggle boards.  It has
# nested classes to represent individual letter blocks (e.g., "a" or
# "qu"), Boggle boards, and a class that can load in a dictionary and
# then solve multiple boards.
class BoggleSolver

  # Represents a letter blocks on the Boggle board.  Generally a
  # letter block will be a single letter (e.g., "a").  However, it can
  # handle letter blocks that can contain sequences (e.g., "qu").  It
  # knows who is neighboring letters are.  It also knows whether it's
  # been used (consumed) yet or not.  Can return a list of all
  # neighboring letters that are not yet used.
  class Letter
    attr_reader :letter, :neighbors
    attr_accessor :used

    
    def initialize(letter)
      @letter = letter
      @neighbors = Set.new
      @used = false
    end


    # Adds a neighbor to the given letter.
    def add_neighbor(other_letter)
      @neighbors << other_letter
    end


    # Returns an array of neighboring letters that are not yet used.
    def unused_neighbors
      @neighbors.reject { |n| n.used }
    end
  end
  

  # Represents a Boggle board as a two-dimensional array of Letters.
  # The letters themselves keep track of the structure of the board
  # (i.e., which letters neighbor which other letters), although the
  # initialize method of this class sets up those links.
  class Board

    # Creates a board from a two-dimensional array of letters.  Note,
    # a letter can actually be a letter sequence (e.g., "qu").
    def initialize(contents)
      @size = contents.size
      raise "non-rectangular" unless @size == contents.first.size
      
      @letters = contents.map do |row|
        row.map { |letter| Letter.new(letter) }
      end
      
      # set up neighbors
      @letters.each_with_index do |row, row_index|
        row.each_with_index do |letter, col_index|
          (-1..1).each do |row_offset|
            r = row_index + row_offset
            next unless (0...@size) === r
            (-1..1).each do |col_offset|
              next if row_offset == 0 && col_offset == 0
              c = col_index + col_offset
              next unless (0...@size) === c
              letter.add_neighbor @letters[r][c]
            end
          end
        end
      end
    end


    # Processes each letter on the board with the block provided.
    def process
      @letters.flatten.each { |l| yield l }
    end
  end


  # Loads a dictionary and solves multiple boards using that dictionary.
  class Solver
    # Provide a dictioary file used to solve the Boggle boards.
    def initialize(dictionary_file)
       @trie = Trie.new
       IO::foreach(dictionary_file) { |line| @trie.add(line.chomp) }
    end


    # Solves the board passed in, returning an array of words, sorted
    # from longest to shortest.
    def solve(board_config)
      board = Board.new(board_config)
      results = Set.new
      board.process do |letter|
        #find_words(letter, "", @trie.root, results)
        find_words(@trie.root,letter,results)
      end
      results.to_a.sort_by { |w| [-w.size, w] }
    end

    
    protected


    # Recursively try to find words by adding this letter to word,
    # looking for it in our dictionary trie, and adding found words to
    # results.
    def find_words(node,letter,results)
      letter.used = true  # open block by making letter used
      
      # march down dictionary trie; note: because one die contains a
      # side w/ "qu", we use generalize to allow a die to contain any
      # number of letters and march through *all* of them using a loop
      letter.letter.each do |x|
        node = node.walk(x)
        if node.nil?
            letter.used = false
            return
        end
      end
    
      # if this specific word so far is in the dictionary add it to the results
      if node.terminal? && node.full_state.size >= 3
        results << node.full_state
      end

      # if there are any possible words once we get here...
      if not node.leaf?
        # try to extend with all unused neighboring letters
        letter.unused_neighbors.each do |l|
          find_words(node,l,results)
        end
      end
      
      letter.used = false  # close block by making letter available
    end
  end  # class Solver
end  # module BoggleSolver

if $0 == __FILE__
    require 'boggle_board_generator.rb'
    board = BoggleBoardGenerator.new
    puts board

    solver = BoggleSolver::Solver.new('boggle.dict')
    solutions = solver.solve(board.board_2d)
    p solutions
end

