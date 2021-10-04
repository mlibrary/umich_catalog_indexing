require 'umich_traject/record/record'
require 'ht_traject/ht_hathifiles.rb'
module UMich
  class AlmaRecord < UMich::Record
    attr_reader :record
    def initialize(record, 
                   hathi_files_info_getter = lambda{|oclc_nums, bib_nums| HathiTrust::HathiFiles.get_hf_info(oclc_nums, bib_nums)}
                  )
      super
      @hathi_files_info_getter = hathi_files_info_getter
    end
    def to_a
      [hathi_holdings, electronic_items, holdings].flatten
    end
    def record_source
      'alma'
    end
    def aleph_id
      aleph_pattern = /^\(MiU\)\d{9}MIU01$/
      alephnum = sys_control_numbers.find{|x| x.match(aleph_pattern)}
      alephnum[5,9] if alephnum
    end
    def electronic_items
      output = elec_items
      output.push(finding_aid) if finding_aid?
      output.push(not_finding_aid_other_electronic_items) if elec_items.empty?
      output.flatten.map{|x| x.to_h }
    end
    def hathi_holdings
      return [] if hathi_items.empty?
      {
        library: 'HathiTrust Digital Library',
        items: hathi_items
      }
    end
    def holdings
      physical_holdings.map do |holding|
        output = holding.to_h
        output["summary_holdings"] = summary_holdings_for(holding.hol_mmsid)
        output["items"] = items_for(holding.hol_mmsid).map do |item|
          item_output = item.to_h
          item_output["record_has_finding_aid"] == finding_aid?
          item_output
        end
        output
      end
    end
    def availability
      output = Array.new
      output.push('avail_circ') if items.any?{|x| x.circulating?}
      output.push('avail_online') if has_electronic_items? || has_available_ht_items?
      output.push('avail_ht_fulltext') if has_available_ht_items?
      #still need avail_etas??
      output
    end
    def institution_codes
      [
        own_field, 
        elec_items.map{|item| item.inistitution_codes } 
      ]
    end
    def locations
      output = [  
        own_field,
        items.map{|x| x.locations},
        physical_holdings.map{|x| x.locations},
      ].flatten 
      output.push('ELEC') if has_electronic_items? 
      output.uniq
    end
    def has_electronic_items?
      !elec_items.empty? or !other_electronic_items.empty?
    end
    def has_available_ht_items?
      hathi_items.any?{|x| x[:access] != 0 }
    end
    def summary_holdings_for(hol_mmsid)
      summary_holdings.select{|x| x.hol_mmsid == hol_mmsid }.map{|x| x.text}.join(' : ')
    end
    def items_for(hol_mmsid)
      items.select{|x| x.hol_mmsid == hol_mmsid }
    end
    def finding_aid
      other_electronic_items.find{|x| x.class.name =~ /FindingAidItem/}
    end
    def not_finding_aid_other_electronic_items
      other_electronic_items.select{|x| x.class.name !~ /FindingAidItem/}
    end
    def finding_aid?
      !finding_aid.nil?
    end
    def oclc_numbers
      sys_control_numbers.map do |value|
        oclc_pattern.match(value){|m| m[1] }
      end.compact
    end
    private
    def sys_control_numbers
      @sys_control_numbers ||= process_tag(['035']) do |f, output|
        output.push(f['a'])
      end
    end
    def own_field
      my_own_field = lamda do
        ouptut = nil
        @record.each_by_tag(['958', 'OWN']) do |f|
          output = f['a']&.upcase
        end
        output
      end
      @own_field ||= my_own_field.call()
    end
    def elec_items
      @elec_items ||= process_tag('E56') do |f, output|
        next if f['u'].nil?
        output.push(ElectronicItem.for(f))
      end
    end
    def other_electronic_items 
      @other_electronic_items  ||= process_tag('856') do |f, output|
        next if f['u'].nil?
        output.push(OtherElectronicItem.for(f))
      end
    end

    def summary_holdings
      @summary_holdings ||= process_tag('866') do |f, output|
        next if f['8'].nil?
        output.push(SummaryHolding.new(f))
      end
    end
    def items
      @items ||= process_tag('974') do |f, output|
        next if f['8'].nil?
        next if f['b'] == 'ELEC'  # ELEC is mistakenly migrated from ALEPH
        next if f['y']&.match?(/Process Status: (EO|SD|CA|WN|WD|MG|CS)/)
        output.push(AlmaItem.new(f))
      end
    end
    def physical_holdings
      @physical_holdings ||= process_tag('852') do |f, output|
        next if f['8'].nil?
        next if f['b'] == 'ELEC'
        output.push(AlmaHolding.new(f))
      end
    end
    def process_tag(tag)
      output = Array.new
      @record.each_by_tag(tag) do |f|
        yield(f, output)
      end
      output
    end
    def hathi_items
      @hathi_items ||= @hathi_files_info_getter.call(oclc_numbers, [id, aleph_id].compact).map do |item|
        #hardcoding etas status for now
        item[:status] = statusFromRights(item[:rights], false)
        item
      end
    end
    def statusFromRights(rights, etas = false)

      if rights =~ /^(pd|world|cc|und-world|ic-world)/
        status = "Full text";
      elsif etas
        status = "Full text available, simultaneous access is limited (HathiTrust log in required)"
      else
        status = "Search only (no full text)"
      end
    end
    def oclc_pattern
      /
      \A\s*
      (?:(?:\(OCoLC\)) |
         (?:\(OCoLC\))?(?:(?:ocm)|(?:ocn)|(?:on))
         )(\d+)
         /x
    end

    class SummaryHolding 
      def initialize(field)
        @field = field
      end
      def hol_mmsid
        @field['8']
      end
      def text
        @field['a']
      end
    end
    class ElectronicItem
      def self.for(field)
        case field['c']
        when 'UMAA'
          AnnArborElectronicItem.new(field)
        when 'UMFL'
          FlintElectronicItem.new(field)
        else
          ElectronicItem.new(field)
        end
      end
      def initialize(field)
        @field = field
      end
      def library
        'ELEC'
      end
      def inistitution_codes
        #default is both FLINT and UMAA
        ['MIU','MIFLIC']
      end
      def link
        campus_ignorant_link.sub("openurl", "openurl-UMAA")
      end
      def status
        @field['s']
      end
      def link_text
        @field['y'] || 'Available online'
      end
      def description
        @field['3']
      end
      def note
        @field['z'] || @field['n'] || @field['m'] || nil
      end
      def interface_name
        @field['m']
      end
      def collection_name
        @field['n']
      end
      def finding_aid
        false
      end
      def to_h
        ["finding_aid","interface_name","library","link","link_text","note","status", "collection_name"].map{|x| [x, public_send(x) ] }.to_h
      end
      private
      def campus_ignorant_link
        URI.escape(@field['u'])
      end
    end
    class AnnArborElectronicItem < ElectronicItem
      def inistitution_codes
        ['MIU']
      end
    end
    class FlintElectronicItem < ElectronicItem
      def inistitution_codes
        ['MIFLIC']
      end
      def link
        campus_ignorant_link.sub("openurl", "openurl-UMFL")
      end
    end
    class OtherElectronicItem < ElectronicItem
      def self.for(field)
        if field['y'] =~ /finding aid/i and f['u6'] =~ /umich/i
          FindingAidItem.new(field)
        else
          OtherElectronicItem.new(field)
        end
      end
      #856 field
      def link
        campus_ignorant_link
      end
      def collection_name
        nil
      end
      def interface_name
        nil
      end
    end
    class FindingAidItem < OtherElectronicItem
      def finding_aid
        true
      end
    end
  end
end
