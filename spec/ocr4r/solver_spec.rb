require "spec_helper"

describe OCR4R::Solver do
  
  it "should convert char to array and back to char" do
    char = 'Z'
    array = subject.send(:convert_to_array, char)
    subject.send(:convert_to_char, array).should == char
  end
  
  it "should normalize the AI output" do
    char = 'y'
    forged_output = char[0].to_s(2).split('').map {|i| i == "1" ? 0.5 * rand + 0.5 : 0.4999 * rand}
    subject.send(:convert_output, forged_output).should == char
  end
  
  it "should convert a char to AI array" do
    file = "[A]arial.bmp"
    subject.send(:convert_file_name, file).should == subject.send(:convert_to_array, 'A')
  end
end