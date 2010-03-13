module OCR4R
  class Decaptcher
    attr_accessor :options, :solver

    def initializer(options)
      @options = options
      @solver = Solver.new(options[:ai])
    end

    def solve(img_file)
      processed_img_file = process_image(img_file)
      char_files = segment_chars(processed_img_file)
      calculate_chars(char_files).gsub(/\W/, '*')
    end

    private
    def process_image(img_file)
      send("process_#{options[:background]}_background", options[:background_threshold])
      send("thin_lines", options[:lines_width])
      send("enfatize_chars", options[:chars_color])
    end

    def calculate_char(char_file)
      solver.solve(char_file.get_pixels)
    end

    def calculate_chars(char_files)
      text = ""
      char_files.each do |char_file|
        text += calculate_char(char_file)
      end
      
      text
    end
  end
end