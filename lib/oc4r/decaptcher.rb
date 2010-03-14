module OCR4R
  class Decaptcher
    attr_accessor :options, :solver

    def initializer(options)
      @options = options
      @solver = Solver.new(options[:ai])
    end

    def solve(img_file)
      image = Magick::ImageList.new(img_file)
      processed_image = process_image(image)
      char_files = segment_chars(processed_image)
      calculate_chars(char_images).gsub(/\W/, '*')
    end

    private
    def process_image(image)
      send("process_#{options[:background]}_background", options[:background_threshold], image)
      send("smooth_lines", options[:lines_width], image)
      send("enfatize_chars", options[:chars_color], image)
    end

    def process_continuous_background(threshold, image)

      image.write('background_treatment.bmp') if options[:debug]
      image
    end

    def smooth_lines(line_width, image)
      line_width.times{image = image.spread}
      image.write('smoothed.bmp') if options[:debug]
      image
    end

    def enfatize_chars(threshold, image)

      image.write('chars_enfatized.bmp') if options[:debug]
      image
    end

    def calculate_char(char_image)
      solver.solve(char_image.get_pixels)
    end

    def calculate_chars(char_images)
      text = ""
      char_images.each do |char_image|
        text += calculate_char(char_image)
      end
      
      text
    end
  end
end