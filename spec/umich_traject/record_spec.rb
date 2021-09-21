require_relative "../spec_helper"
require 'marc'
require 'pry-debugger-jruby'
require 'umich_traject/holdings.rb'
describe UMich::Record::Item do
  before(:each) do
    reader = MARC::XMLReader.new('./spec/fixtures/alma_example.xml')
    record = reader.first
    @holding_field = nil
    record.each_by_tag('974') do |f|
      @holding_field = f
    end
    @lib_loc_info = {
      'BUHR MAIN' => { "info_link" => 'INFO_LINK', "name" => 'Buhr Shelving Facility' }
    }
    
  end
  subject do
    described_class.new(@holding_field, @lib_loc_info)
  end
  it "has hol_mmsid" do
    expect(subject.hol_mmsid).to eq('22923776740006381')
  end
  it "has barcode" do
    expect(subject.barcode).to eq("B1753008")
  end
  it "has library" do
    expect(subject.library).to eq("BUHR")
  end
  it "has location" do
    expect(subject.location).to eq("MAIN")
  end
  it "has info link" do
    expect(subject.info_link).to eq("INFO_LINK")
  end
  it "has display name" do
    expect(subject.display_name).to eq("Buhr Shelving Facility")
  end

  it "has permanent_library" do
    expect(subject.permanent_library).to eq("BUHR")
  end
  it "has permanent_location" do
    expect(subject.permanent_location).to eq("MAIN")
  end
  it "has temp location boolean" do
    expect(subject.temp_location).to eq(false)
  end
  it "has can_reserve boolean" do
    expect(subject.can_reserve).to eq(false)
  end
  it "has callnumber" do
    expect(subject.callnumber).to eq("MICRO-F 4113 no.188")
  end
  it "has public_note" do
    expect(subject.public_note).to be_nil
  end
  it "has process_type" do
    expect(subject.process_type).to be_nil
  end
  it "has item_policy" do
    expect(subject.item_policy).to eq("01")
  end
  it "has description" do
    expect(subject.description).to be_nil
  end
  it "has inventory_number" do
    expect(subject.inventory_number).to be_nil
  end
  it "has item_id" do
    expect(subject.item_id).to eq("23923776730006381")
  end
end
