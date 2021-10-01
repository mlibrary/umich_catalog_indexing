require_relative "../spec_helper"
require 'marc'
require 'traject'
require 'pry-debugger-jruby'
require 'umich_traject/record/alma_item.rb'
require 'umich_traject/record/alma_holding.rb'
require 'umich_traject/record/alma_record.rb'
describe UMich::AlmaRecord do
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
  context "#aleph_id" do
    it "outputs the correct aleph id" do
      expect(subject.aleph_id).to eq('004160292')
    end
  end
end
