require_relative "../spec_helper"
require 'pry-debugger-jruby'
require 'marc'
require 'traject'
require 'umich_traject/record/hathi_record.rb'
describe UMich::HathiRecord do
  before(:each) do
    @record = MARC::Record.new_from_hash(JSON.parse(File.read('./spec/fixtures/ht_not_umich.json')))
  end
  subject do
    described_class.new(@record)
  end
  it "has holding" do
    expect(subject.holding.class.to_s).to eq('Hash')
  end
end
