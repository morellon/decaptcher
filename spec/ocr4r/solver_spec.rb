require "spec_helper"

describe OCR4R::Solver do
  it "should convert a char to AI array" do
    char_number = 'A'[0]
    file = "[A]arial.bmp"
    output = Array.new(126, 0)
    output[char_number] = 1
    subject.send(:convert_file_name, file).should == output
  end
  
  it "should convert AI array to char" do
    char_number = 'A'[0]
    output = Array.new(126, 0)
    output[char_number] = 1
    subject.send(:convert_output, output).should == 'A'
  end
end