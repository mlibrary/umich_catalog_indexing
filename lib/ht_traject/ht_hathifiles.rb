require 'traject'
require_relative 'ht_dbh'
require 'sequel'

module HathiTrust

  class Hathifiles
    DB = HathiTrust::DBH::DB

    SELECTED_COLS = [
      Sequel[:hf][:htid].as(:id),
      Sequel[:rights_code].as(:rights),
      :description,
      :collection_code,
      :access
    ]

    CC_TO_OF = ::Traject::TranslationMap.new('ht/collection_code_to_original_from')


    # Note how for both oclc_nums and bibs we need to map everything to strings,
    # since the database stores those values as strings. Confusingly, you'll get the
    # right answer if you send ints becauyse mysql will silently change them, but it
    # will then refuse to use the indexes!
    def self.oclc_query(oclc_nums)
      oclc_join = DB[:hf].join(:hf_oclc, htid: :htid)
      hf_htid = Sequel[:hf][:htid]
      oclc_join.select(*SELECTED_COLS).
        where(source: 'MIU').
        where(value: Array(oclc_nums).map(&:to_s))
    end

    def self.bib_query(bib_nums)
      bib_join = DB[:hf].join(:hf_source_bib, htid: :htid)
      bib_join.select(*SELECTED_COLS).
        where(value: Array(bib_nums).map(&:to_s))
    end

    def self.query(bib_nums:, oclc_nums:)
      self.bib_query(bib_nums).union(self.oclc_query(oclc_nums))
    end

    #DB.logger = Logger.new($stdout)
    # I use a db driver per thread to avoid any conflicts
    def self.get_hf_info(oclc_nums, bib_nums)
      oclc_nums = Array(oclc_nums)
      bib_nums = Array(bib_nums)
      hf_hash = Hash.new

      self.query(bib_nums: bib_nums, oclc_nums: oclc_nums).each do |r|
        hf_hash[r[:id]] = r
        hf_hash[r[:id]]['source'] = CC_TO_OF[r[:collection_code].upcase]
      end

      hf_hash.values
    end

  end
end


