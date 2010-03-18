$:.unshift "lib"
require "ocr4r"
`rm *.bmp`
image = Magick::ImageList.new "test.jpg"
decap = OCR4R::Decaptcher.new :lines_width => 0, :debug => true, :background_threshold => 0x6000
#decap.send(:process_image, image)
decap.generate_char_files("test.jpg")