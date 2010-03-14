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
      image = image.quantize(256, Magick::GRAYColorspace)
      image = send("process_background", options[:background_threshold], image)
      image = send("smooth_lines", options[:lines_width], image)
      image = send("emphasize_chars", options[:char_threshold], image)
      image = image.reduce_noise(0)
      image.write('processed.bmp') if options[:debug]
      image

    end

    def process_background(threshold, image)
      tone = image.get_pixels(3, 3, 1, 1).red
      image = tone >= 128 ? image.white_threshold(threshold) : image.black_threshold(threshold)
      image.write('background_treatment.bmp') if options[:debug]
      image
    end

    def smooth_lines(line_width, image)
      # or blur_image?
      line_width.times{image = image.spread}
      image.write('smoothed.bmp') if options[:debug]
      image
    end

    def emphasize_chars(threshold, image)
      tone = image.get_pixels(3, 3, 1, 1).red
      image = tone < 128 ? image.white_threshold(threshold) : image.black_threshold(threshold)
      image.write('chars_emphasized.bmp') if options[:debug]
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