class HangMan
  
  def initialize(guessing_player, checking_player)
    @guessing_player = guessing_player
    @checking_player = checking_player
  end
  
  def play
    @checking_player.choose_secret_word
    @guessing_player.receive_secret_length(@checking_player.word_length)
    until solved?
      current_guess = @guessing_player.guess
      response = @checking_player.check_guess(current_guess)
      @guessing_player.handle_guess_response(response)
    end
    puts "Hooray!  The word was #{@checking_player.secret_word}."
  end
  
  private
  
  def solved?
    @checking_player.solved?
  end
  
end

class ComputerClass
  
  attr_accessor :secret_word, :remaining_words, :guessed_letters, :board
  
  def initialize
    @remaining_words = import_dictionary
    @guessed_letters = []
  end
  
  def import_dictionary
    File.readlines('dictionary.txt').map(&:chomp) 
  end
  
  def choose_secret_word
    @secret_word = @remaining_words.sample
    @board = Array.new(@secret_word.length, "_")
  end
  
  def guess
    current_guess = most_common_unused_letter
    @guessed_letters << current_guess
    current_guess
  end 

  def word_length
    @secret_word.length
  end
  
  def receive_secret_length(length)
    @remaining_words.select! {|word| word.length == length}
  end
  
  def solved?
    @board.join("") == @secret_word
  end
  
  def check_guess(guess)
    @secret_word.split("").each_with_index do |letter, idx|
      if guess == letter
        @board[idx] = letter
        puts "You found one!"
      end
    end
    puts "Try again" unless solved?
    show_board
  end
  
  def show_board
    puts @board.join("")
  end
  
  def handle_guess_response(response)
    if response.class == Array
      happy_update_dictionary(response)
    else
      sad_update_dictionary(response)
    end
  end
  
  private
  
  def sad_update_dictionary(response)
    @remaining_words.select! do |word| 
      !word.split("").any? {|l| l == response}
    end
  end
  
  def happy_update_dictionary(response)
    response.each do |pair|
      reduce_dictionary(pair)
    end
  end
  
  def reduce_dictionary(pair)
    @remaining_words.select! do |word|
      word.split("")[pair[1]] == pair[0]
    end
  end
  
  def most_common_unused_letter
    letter_occurrences = count_remaining_letters
    
    letter_occurrences.max_by { |key, value| value }[0]
  end
  
  def count_remaining_letters
    letter_occurrences = Hash.new(0)
    @remaining_words.each do |word|
      word.each_char do |char|
        letter_occurrences[char] += 1 unless @guessed_letters.include?(char)
      end
    end
    letter_occurrences
  end
      
end


class HumanClass
  class InputError < StandardError; end
  
  attr_accessor :word_length, :found_letter, :winning_spots
  
  def initialize
    @winning_spots = []
  end
  
  def choose_secret_word
    puts "Enter length of secret word"
    @word_length = gets.chomp.to_i
  end
  
  def receive_secret_length(length)
    puts "The word is #{length} long."
    length
  end
  
  def guess
    begin
      puts "Pick a letter"
      input = gets.chomp
      raise InputError.new("Not a valid input") unless validate_input?(input)
      input
    rescue InputError => error
      puts error
      retry
    end
  end
  
  def solved?
    @winning_spots.length == @word_length
  end
  
  def handle_guess_response(response)
    
  end
  
  def check_guess(guess)
    if exists?(guess)
      ask_position(guess)
      @winning_spots
    else
      guess
    end
  end
  
  def secret_word
    assembled_word = []
    @winning_spots.each do |arr|
      assembled_word[arr[1]] = arr[0]
    end
    assembled_word.join("")
  end  
  
  private
  
  def validate_input?(letter)
    ("a".."z").to_a.include?(letter.downcase)
  end
  
  def exists?(guess)
    puts "Is the letter #{guess} in the word? (Y/N)"
    gets.chomp.downcase == "y"
  end
  
  def ask_position(guess)
    puts "Ooh! I found one!  Where does it go?"
    begin
      input = gets.chomp.to_i
      raise InputError.new("Not a valid input") unless valid_location?(input)
       @winning_spots << [guess, input]
      puts "Are there any more occurences?(Y/N)" if !solved?
      if gets.chomp.downcase == "y"
        ask_position(guess)
      end
      
    rescue InputError => error
      puts error
      retry
    end
  end
  
  def valid_location?(location)
    (0...@word_length).to_a.include?(location) && not_already_chosen(location)
  end
  
  def not_already_chosen(location)
    !@winning_spots.any? do |group|
      group[1] == location
    end
  end

end


isis = HumanClass.new
puter = ComputerClass.new

game = HangMan.new(puter, isis)

game.play
