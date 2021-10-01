require_relative "../spec_helper"
require 'marc'
require 'pry-debugger-jruby'
require 'umich_traject/record/alma_holding.rb'
describe UMich::AlmaRecord::AlmaHolding do
  before(:each) do
    reader = MARC::XMLReader.new('./spec/fixtures/alma_example.xml')
    record = reader.first
    @holding_field = nil
    record.each_by_tag('852') do |f|
      @holding_field = f
    end
    @lib_loc_info = {
      'BUHR MAIN' => { "info_link" => 'INFO_LINK', "name" => 'Buhr Shelving Facility' }
    }
    
  end
  subject do
    described_class.new(@holding_field, @lib_loc_info)
  end
  it "has an output hash" do 
    expect(subject.to_h.class.name).to eq('Hash')
  end
end
