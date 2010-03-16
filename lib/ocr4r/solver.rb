module OCR4R
  class Solver
    attr_accessor :options, :ai

    INPUT_PIXELS = 256
    CHARS = 126

    def initialize(options={})
       @options = {:hidden_neurons => []}.merge(options)
       puts "hidden #{@options[:hidden_neurons].inspect}"
       @ai = Ai4r::NeuralNetwork::Backpropagation.new([INPUT_PIXELS]+@options[:hidden_neurons]+[CHARS])
       @ai.weights = @options[:weigths]
    end

    def solve(pixels)
       convert_output(@ai.eval(pixels))
    end

    def train(perfect_directory, noisy_directory)
       @ai = Ai4r::NeuralNetwork::Backpropagation.new([INPUT_PIXELS]+options[:hidden_neurons]+[CHARS])
       Dir.entries(perfect_directory).each do |file|
          next unless file =~ /\.bpm$/
          output = convert_file_name(file)
          100.times{@ai.train(file.get_pixels, output)}
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
      raise "Unknown file name format: #{file}" unless file =~ /\[(.)\].*\.bmp$/i
      char = $1
      puts "veio char: #{char}"
      code = char[0]
      output = Array.new(CHARS, 0)
      output[code] = 1
      output
    end
  end
end