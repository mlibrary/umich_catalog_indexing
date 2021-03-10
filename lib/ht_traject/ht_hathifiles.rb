require 'traject'
require_relative '../ht_secure_data'
require 'sequel'

module HathiTrust

  class Hathifiles
    extend HathiTrust::SecureData
    DB = Sequel.connect("jdbc:mysql://#{db_machine}/#{db_db}?user=#{db_user}&password=#{db_password}")
    HF_oclc_query = DB[:hf].join(:hf_oclc, htid: :htid).select(Sequel[:hf][:htid].as(:id), Sequel[:rights_code].as(:rights), :description, :collection_code, )
    HF_source_bib_num_query = DB[:hf].join(:hf_source_bib, htid: :htid).select(Sequel[:hf][:htid].as(:id), Sequel[:rights_code].as(:rights), :description, :collection_code,  )

#DB.logger = Logger.new($stdout)
    # I use a db driver per thread to avoid any conflicts
    def self.get_hf_info(oclc_nums, bib_nums)
#to_field 'htsource' do |record, acc, context|
#  cc_to_of = Traject::TranslationMap.new('ht/collection_code_to_original_from')
#  acc.concat context.clipboard[:ht][:items].collection_codes.map { |x| cc_to_of[x] } if context.clipboard[:ht][:has_items]
#end
      cc_to_of = ::Traject::TranslationMap.new('ht/collection_code_to_original_from')
      oclc_nums = Array(oclc_nums)
      bib_nums = Array(bib_nums)
      hf_hash = Hash.new()

      HF_source_bib_num_query.where(:value => bib_nums).where(source: "MIU").each do |r|
        hf_hash[r[:id ]] = r
        hf_hash[r[:id]]['source'] = cc_to_of[r[:collection_code]]
      end
      HF_oclc_query.where(:value => oclc_nums).each do |r|
        hf_hash[r[:id ]] = r
        hf_hash[r[:id]]['source'] = cc_to_of[r[:collection_code]]
      end

      hf_hash.values
    end

  end
end


