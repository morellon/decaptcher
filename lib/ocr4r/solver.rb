require "ruby-debug"

module OCR4R
  class Solver
    attr_accessor :options, :ai

    INPUT_PIXELS = 256
    CHARS = 126
    THRESHOLD = 0

    def initialize(options={})
       @options = {:hidden_neurons => [], :training_amount => 100}.merge(options)
       @ai = Ai4r::NeuralNetwork::Backpropagation.new([INPUT_PIXELS]+@options[:hidden_neurons]+[output_array_size])
       @ai.set_parameters( 
           #:momentum => 0.1, 
           :learning_rate => 0.5
           #:propagation_function => lambda { |x| Math.tanh(x) },
           #:derivative_propagation_function => lambda { |y| 1.0 - y**2 }
           )
       
       @ai.init_network
       @ai.weights = @options[:weights] if @options[:weights]
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
    
    def output_array_size
      CHARS.to_s(2).length
    end
    
    def convert_to_char(array)
      (array.join('').to_i(2) - THRESHOLD).chr
    end
    
    def convert_to_array(char)
      bin = (char[0] + THRESHOLD).to_s(2)
      zeros_length = output_array_size - bin.length
      Array.new(zeros_length,0) + bin.split('').map{|i| i.to_i}
    end
    
    def convert_output(result)
      max = 0
      result = result.map {|item| item > 0.5 ? 1 : 0}
      puts "resultado: #{result}"
      convert_to_char(result)
    end

    def convert_file_name(file)
      raise "Unknown file name format: #{file}" unless file =~ /\[(.)\].*\.bmp$/i
      char = $1
      puts "training char: #{char}"
      convert_to_array(char)
    end
    
    def get_pixels(file)
      image = Magick::ImageList.new(file)
      pixels = image.get_pixels(0,0,16,16).map {|pixel| pixel.red == 0 ? 0 : 1}
      pixels
    end
  end
end