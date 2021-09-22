require_relative "../spec_helper"
require 'marc'
require 'traject'
require 'pry-debugger-jruby'
require 'umich_traject/record/item.rb'
require 'umich_traject/record/holding.rb'
require 'umich_traject/record/record.rb'
describe UMich::Record do
  before(:each) do
    reader = MARC::XMLReader.new('./spec/fixtures/alma_example.xml')
    @record = reader.first
  end
  subject do
    described_class.new(@record)
  end
  it "outputs an array" do
    puts subject.to_a
    expect(subject.to_a.class.name).to eq('Array')
  end
end
