module OCR4R
  class Solver
    attr_accessor :options, :ai

    FILE_CODES = {
      :left_parenthesis => '(',
      :right_parenthesis => ')',
      :question_mark => '?',
      :exclamation_mark => '!',
      :ending_dot => '.',
      :colon => ':',
      :comma => ',',
      :dot_comma => ';'
    }

    INPUT_PIXELS = 256
    CHARS = 126

    def initialize(options)
       @options = options
       @ai = Ai4R::NeuralNetwork::BackPropagation.new([INPUT_PIXELS]+options[:hidden_neurons]+[CHARS])
       @ai.load_weigths(options[:weigths])
    end

    def solve(pixels)
       convert_output(@ai.eval(pixels))
    end

    def train(perfect_directory, noisy_directory)
      @ai = Ai4R::NeuralNetwork::BackPropagation.new([INPUT_PIXELS]+options[:hidden_neurons]+[CHARS])
      Dir.entries(perfect_directory).each do |file|
         next unless file =~ /\.bpm$/
         output = convert_file_name(file)
         100.times{@ai.train(file.get_pixels, output)
      end

      Dir.entries(noisy_directory).each do |file|
         next unless file =~ /\.bpm$/
         output = convert_file_name(file)
         @ai.train(file.get_pixels, output)
      end

      @ai.weights
    end

    private
    def convert_output(result)
      max = 0
      result.each {|item| max = item > max ? item : max}
      result.index(max).chr
    end

    def convert_file_name(file)
      raise "Unknown file name format: #{file}" unless file =~ /\[(.+)(_(upcase|downcase))?\]\d+\.bmp$/i
      char = $1
      char_type = $3
      char = char.send(char_type.downcase) if char_type
      code = char[0]
      output = Array.new(CHARS, 0)
      output[code] = 1
      output
    end
  end
end