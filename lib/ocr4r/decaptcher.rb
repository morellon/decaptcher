module OCR4R
  class Decaptcher
    attr_accessor :options, :solver

    def initialize(options={})
      @options = {:background_threshold => 0x8000, :char_threshold => 0x8000, :lines_width => 0, :ai => {}}.merge(options)
      @solver = Solver.new(@options[:ai])
    end

    def solve(img_file)
      image = Magick::ImageList.new(img_file)
      processed_image = process_image(image)
      char_files = segment_chars(processed_image)
      calculate_chars(char_images).gsub(/\W/, '*')
    end
    
    
    def generate_char_files(img_file)
      image = Magick::ImageList.new(img_file)
      processed_image = process_image(image)
      char_files = segment_chars(processed_image)
    end

    private
    def process_image(image)
      image = smooth_lines(image, options[:lines_width])
      image = gray(image)
      image = process_background(image, options[:background_threshold])
      image = emphasize_chars(image, options[:char_threshold])
      image.write('processed.bmp') if options[:debug]
      image
    end
    
    def gray(image)
      image = image.quantize(256, Magick::GRAYColorspace)
      image.write('gray_scale.bmp') if options[:debug]
    end

    def process_background(image, threshold)
      tone = image.get_pixels(3, 3, 1, 1)[0].red
      image = tone >= 128 ? image.white_threshold(threshold) : image.black_threshold(threshold)
      image.write('background_treatment.bmp') if options[:debug]
      image
    end

    def smooth_lines(image, line_width)
      #TODO: try using convolve
      line_width.times{image = image.blur_image}
      image.write('smoothed.bmp') if options[:debug]
      image
    end

    def emphasize_chars(image, threshold)
      tone = image.get_pixels(3, 3, 1, 1)[0].red
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
    
    def segment_chars(image)
      white_averages = []
      image.columns.times do |i|
        total = 0
        image.get_pixels(i, 0, 1, image.rows).each{|pixel| total += pixel.red}
        white_averages << (total/image.rows)
      end
      
      chars_placement = []
      last_average = white_averages[0]
      white_averages.each do |average|
        has_char = (65535 - average > 500) ? 1 : 0
        chars_placement << has_char
        last_average = average
      end
      
      puts chars_placement.inspect
      
      limits = []
      chars_placement[1..-2].each_index do |i|
        limits << i if edge?(chars_placement, i)
      end
      
      puts limits.inspect
      
      chars_amounts = (limits.size/2)
      chars = []
      chars_amounts.times do |i|
        chars << [limits[2*i], limits[2*i+1]]
      end
      
      char_files = []
      i = 0
      chars.each do |char|
        char_img = image.crop(char[0], 0, char[1]-char[0]+1, image.rows)
        i+= 1
        file = "char#{i}.bmp"
        char_img.write(file)
        char_files << file
      end
      
      char_files
    end
    
    def edge?(chars_placement, index)
      chars_placement[index] - chars_placement[index-1] > 0 || chars_placement[index+1] - chars_placement[index] < 0
    end
  end
end