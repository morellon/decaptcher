module OCR4R
  class Decaptcher
    attr_accessor :options, :solver

    def initialize(options={})
      @options = {:background_threshold => 0x8000, :char_threshold => 0x8000, :lines_width => 0, :ai => {}}.merge(options)
      @solver = Solver.new(@options[:ai])
      FileUtils.mkdir_p(destination_dir)
    end

    def solve(img_file)
      image = Magick::ImageList.new(img_file)
      processed_image = process_image(image)
      char_images = BasicSegmenter.new.segment_word(processed_image)
      
      calculate_chars(char_images)
    end
    
    
    def generate_char_files(img_file, initial_char = 'A', suffix = "created")
      image = Magick::ImageList.new(img_file)
      processed_image = process_image(image)
      char_files = segment_chars(processed_image)
      char_num = initial_char.ord
      char_files.map do |char_file|
        trimmed = trim_height(char_file).resize(16, 16)
        trimmed.write("[#{char_definition(char_num)}]#{suffix}.bmp")
        char_num += 1
      end
    end

    private
    def process_image(image)
      image = smooth_lines(image, options[:lines_width])
      image = gray(image)
      image = process_background(image, options[:background_threshold])
      image = emphasize_chars(image, options[:char_threshold])
      
      image.write("#{destination_dir}/processed.bmp") if options[:debug]
      image
    end
    
    def gray(image)
      image = image.quantize(256, Magick::GRAYColorspace)
      image.write("#{destination_dir}/gray_scale.bmp") if options[:debug]
      image
    end

    def process_background(image, threshold)
      tone = image.get_pixels(3, 3, 1, 1)[0].red
      image = tone >= 128 ? image.white_threshold(threshold) : image.black_threshold(threshold)
      image.write("#{destination_dir}/background_treatment.bmp") if options[:debug]
      image
    end

    def smooth_lines(image, line_width)
      #TODO: try using convolve
      line_width.times{image = image.blur_image}
      image.write("#{destination_dir}/smoothed.bmp") if options[:debug]
      image
    end

    def emphasize_chars(image, threshold)
      tone = image.get_pixels(3, 3, 1, 1)[0].red
      image = tone < 128 ? image.white_threshold(threshold) : image.black_threshold(threshold)
      image.write("#{destination_dir}/chars_emphasized.bmp") if options[:debug]
      image
    end

    def calculate_chars(char_images)
      text = ""
      char_images.each do |char_image|
        text += solver.solve(char_image)
      end
      
      text
    end
    
    def destination_dir
      @destination_dir ||= "/tmp/ocr4r_#{(10000*rand).to_i}"
    end
  end
end