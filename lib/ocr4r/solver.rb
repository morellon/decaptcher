require "ruby-debug"

module OCR4R
  class Solver
    attr_accessor :options, :ai

    INPUT_PIXELS = 256
    CHARS = 126

    def initialize(options={})
       @options = {:hidden_neurons => [], :training_amount => 100}.merge(options)
       @ai = Ai4r::NeuralNetwork::Backpropagation.new([INPUT_PIXELS]+@options[:hidden_neurons]+[CHARS])
       @ai.init_network
       @ai.weights = @options[:weights]
    end

    def solve(file)
      pixels = get_pixels(file)
      convert_output(@ai.eval(pixels))
    end

    def train(perfect_directory, noisy_directory = nil)
       options[:training_amount].times do |i|
         Dir.entries(perfect_directory).each do |file|
            next unless file =~ /\.bmp$/
            puts "Train ##{i}:"
            output = convert_file_name(file)
            error = @ai.train(get_pixels("#{perfect_directory}/#{file}"), output)
            puts "training error: #{error}"
         end
       end if perfect_directory
 
       Dir.entries(noisy_directory).each do |file|
          next unless file =~ /\.bmp$/
          output = convert_file_name(file)
          @ai.train(get_pixels("#{perfect_directory}/#{file}"), output)
       end if noisy_directory
 
       @ai.weights
    end

    private
    def convert_output(result)
      max = 0
      result.each {|item| max = item > max ? item : max}
      puts "resultado: #{result.index(max)}"
      result.index(max).chr
    end

    def convert_file_name(file)
      raise "Unknown file name format: #{file}" unless file =~ /\[(.)\].*\.bmp$/i
      char = $1
      puts "training char: #{char}"
      code = char[0]
      output = Array.new(CHARS, 0)
      output[code] = 1
      output
    end
    
    def get_pixels(file)
      image = Magick::ImageList.new(file)
      pixels = image.get_pixels(0,0,16,16).map {|pixel| pixel.red == 0 ? 0 : 1}
      pixels
    end
  end
end