module OCR4R
  class BasicSegmenter
    CHAR_ROW_AVERAGE = 100
    CHAR_COLUMN_AVERAGE = 500
    
    def initialize
      FileUtils.mkdir_p(destination_dir)
    end
    
    def segment_word(image)
      char_images = segment_chars(image)
      
      i = 0
      char_images.map do |char_image|
        char_file = "#{destination_dir}/#{i}.bmp"
        char_image.write(char_file)
        char_image = Magick::ImageList.new(char_file)
        
        char_image = trim_height(char_image).resize(16, 16)
        char_image.write(char_file)
        i += 1
        
        char_image
      end
    end
    
    private
    def segment_chars(image, char_column_average = CHAR_COLUMN_AVERAGE)
      
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
        has_char = (65535 - average > char_column_average) ? 1 : 0
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
      
      chars.map do |char|
        image.crop(char[0], 0, char[1]-char[0]+1, image.rows)
      end
    end
    
    def trim_height(image, char_row_average = CHAR_ROW_AVERAGE)
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
        has_char = (65535 - average > char_row_average) ? 1 : 0
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
    
    def destination_dir
      @destination_dir ||= "/tmp/ocr4r/segmenter_#{(10000*rand).to_i}"
    end
  end
end