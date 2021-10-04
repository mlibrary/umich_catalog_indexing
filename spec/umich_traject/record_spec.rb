require_relative "../spec_helper"
require 'marc'
require 'traject'
require 'pry-debugger-jruby'
require 'umich_traject/record/record.rb'
require 'umich_traject/record/alma_item.rb'
require 'umich_traject/record/alma_holding.rb'
require 'umich_traject/record/alma_record.rb'
describe UMich::AlmaRecord do
  before(:each) do
    reader = MARC::XMLReader.new('./spec/fixtures/alma_example.xml')
    @ht_output = [{:id=>"mdp.39015006117157", :rights=>"ic", :description=>"", :collection_code=>"MIU", :access=>0, "source"=>"University of Michigan"}]
    @record = reader.first
    @hf_getter_method = lambda{|oclc_nums, bib_nums| @ht_output }
  end
  subject do
    described_class.new(@record, @hf_getter_method)
  end
  it "outputs an array" do
    expect(subject.to_a.class.name).to eq('Array')
  end
  context "#aleph_id" do
    it "outputs the correct aleph id" do
      expect(subject.aleph_id).to eq('004160292')
    end
  end
  context "#oclc_numbers" do
    it "outputs oclc numbers" do
      expect(subject.oclc_numbers).to eq(["46721391"])
    end
  end
  context "#availability" do
    it "output availability" do
      expect(subject.availability).to eq([])
    end
  end
end
