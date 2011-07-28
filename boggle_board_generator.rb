#!/usr/bin/env ruby
# Represents and generates Boggle Boards.  It randomly rolls simulated
# Boggle Dice and places them randomly in a 4x4 grid.  Note: one die
# has a side that shows 'qu'.

require 'enumerator'

class BoggleBoardGenerator
  BoggleDie = [
    ['f', 'o', 'r', 'i', 'x', 'b'],
    ['m', 'o', 'qu', 'a', 'b', 'j'],
    ['g', 'u', 'r', 'i', 'l', 'w'],
    ['s', 'e', 't', 'u', 'p', 'l'],
    ['c', 'm', 'p', 'd', 'a', 'e'],
    ['a', 'c', 'i', 't', 'a', 'o'],
    ['s', 'l', 'c', 'r', 'a', 'e'],
    ['r', 'o', 'm', 'a', 's', 'h'],
    ['n', 'o', 'd', 'e', 's', 'w'],
    ['h', 'e', 'f', 'i', 'y', 'e'],
    ['o', 'n', 'u', 'd', 't', 'k'],
    ['t', 'e', 'v', 'i', 'g', 'n'],
    ['a', 'n', 'e', 'd', 'v', 'z'],
    ['p', 'i', 'n', 'e', 's', 'h'],
    ['a', 'b', 'i', 'l', 'y', 't'],
    ['g', 'k', 'y', 'l', 'e', 'u']]

  attr_reader :board
  
  def initialize()
    indices = (0...BoggleDie.size).to_a.sort_by { rand }

    # creates an array with the dice randomly re-ordered and then
    # rolls each of the dice
    @board = BoggleDie.values_at(*indices).map { |die| die[rand(die.size)] }
  end

  # Returns an array of arrays, where outer arrays contains the rows
  # on the board, and each row is an array that contains the letters
  # on a given row.
  def board_2d
    # slice the array into groups of 4 to create 2d-array
    @board.each_slice(4).to_a
  end


  # Returns a string that displays the rows on separate lines.
  def to_s
    board_2d.map do |row|
      row.map { |letter| '%-3s' % letter }.join(' ')
    end.join("\n")
  end
end


if $0 == __FILE__
    b = BoggleBoardGenerator.new
    puts b         # 4-line string
end

