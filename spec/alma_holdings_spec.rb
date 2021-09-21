require_relative "./spec_helper"
describe "Holding structure" do
 it "outputs something" do
    indexer = Traject::Indexer.new
    indexer.configure do 
    
      require 'set'
      require 'pry-debugger-jruby'
      
      require 'library_stdnums'
      
      require 'traject/macros/marc21'
      extend Traject::Macros::Marc21
      require 'traject/macros/marc21_semantics'
      extend Traject::Macros::Marc21Semantics
      
      require 'traject/macros/marc_format_classifier'
      extend Traject::Macros::MarcFormats
      
      require 'ht_traject'
      extend HathiTrust::Traject::Macros
      extend Traject::UMichFormat::Macros
      
      require 'marc/fastxmlwriter'
      
      require 'marc_record_speed_monkeypatch'
      require 'marc4j_fix'
    
      #to_field 'aleph_id' do |record, acc, context|
        #if context.clipboard[:ht][:record_source] == 'alma'
          #aleph_spec = Traject::MarcExtractor.cached('035a')
          #aleph_spec.extract(record).grep(aleph_pattern).each { |alephnum|
            #acc << alephnum[5, 9]
          #}
        #end
      #end
    end
    indexer.load_config_file('./indexers/common.rb')
    indexer.load_config_file('./indexers/umich_alma.rb')
    reader = MARC::XMLReader.new('./spec/fixtures/alma_example.xml')
    json = indexer.map_record(reader.first)
    expect(JSON.parse(json["hol"].first)).to eq(JSON.parse(fixture('alma_holdings_example.json')))
 end
end
