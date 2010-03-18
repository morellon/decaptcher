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
      
      char_images = []
      char_files.map do |char_file|
        char_images << trim_height(char_file).resize(16, 16)
      end
      calculate_chars(char_images).gsub(/\W/, '*')
    end
    
    
    def generate_char_files(img_file, suffix = "created")
      image = Magick::ImageList.new(img_file)
      processed_image = process_image(image)
      char_files = segment_chars(processed_image)
      char = 'A'
      char_files.map do |char_file|
        trimmed = trim_height(char_file).resize(16, 16)
        trimmed.write("[#{char}]#{suffix}.bmp")
        char.next!
      end
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
      image
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
      solver.solve(char_image.get_pixels(0,0,char_image.columns,char_image.rows))
    end

    def calculate_chars(char_images)
      text = ""
      char_images.each do |char_image|
        text += calculate_char(char_image)
      end
      
      text
    end
    
    def segment_chars(image)
      #column pixels average
      white_averages = []
      image.columns.times do |i|
        total = 0
        image.get_pixels(i, 0, 1, image.rows).each{|pixel| total += pixel.red}
        white_averages << (total/image.rows)
      end
      
      #find which column may have a char part
      chars_placement = []
      white_averages.each do |average|
        has_char = (65535 - average > 500) ? 1 : 0
        chars_placement << has_char
      end
      
      #find edges
      limits = []
      chars_placement[1..-2].each_index do |i|
        limits << i if edge?(chars_placement, i)
      end
      
      #group pair of edges
      chars_amounts = (limits.size/2)
      chars = []
      chars_amounts.times do |i|
        chars << [limits[2*i], limits[2*i+1]]
      end
      
      #segment images
      char_images = []
      i = 0
      chars.each do |char|
        char_img = image.crop(char[0], 0, char[1]-char[0]+1, image.rows)
        i+= 1
        file = "segmented#{i}.bmp"
        char_img.write(file)
        char_images << file
      end
      
      char_images
    end
    
    def trim_height(img_file)
      image = Magick::ImageList.new(img_file)
      #row pixels average
      white_averages = []
      image.rows.times do |i|
        total = 0
        image.get_pixels(0, i, image.columns, 1).each{|pixel| total += pixel.red}
        white_averages << (total/image.columns)
      end
      
      #find which column may have a char part
      chars_placement = []
      white_averages.each do |average|
        has_char = (65535 - average > 100) ? 1 : 0
        chars_placement << has_char
      end
      
      #find edges
      limits = []
      chars_placement[1..-2].each_index do |i|
        limits << i if edge?(chars_placement, i)
      end
      
      image.crop(0, limits[0], image.columns, limits[1] - limits[0] + 1)
    end
      
    
    def edge?(chars_placement, index)
      chars_placement[index] - chars_placement[index-1] > 0 || chars_placement[index+1] - chars_placement[index] < 0
    end
  end
end