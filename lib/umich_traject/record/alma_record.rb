module UMich
  class AlmaRecord
    attr_reader :record
    def initialize(record)
      @record = record
      @elec_items = get_electronic_items 
      @other_electronic_items = get_other_electronic_items
      @own_field = get_own_field
      @summary_holdings = get_summary_holdings
      @holdings = get_holdings
      @items = get_items
      @sys_control_numbers = get_sys_control_numbers
    end
    def to_a
      [electronic_items, holdings].flatten
    end
    def aleph_id
      aleph_pattern = /^\(MiU\)\d{9}MIU01$/
      alephnum = @sys_control_numbers.find{|x| x.match(aleph_pattern)}
      alephnum[5,9] if alephnum
    end
    def electronic_items
      output = @elec_items
      output.push(finding_aid) if finding_aid?
      output.push(not_finding_aid_other_electronic_items) if @elec_items.empty?
      output.flatten.map{|x| x.to_h }
    end
    def holdings
      @holdings.map do |holding|
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
      output.push('avail_circ') if @items.any?{|x| x.circulating?}
      output.push('avail_online') if has_electronic_items?
      output
    end
    def institution_codes
      [
        @own_field, 
        @elec_items.map{|item| item.inistitution_codes } 
      ]
    end
    def locations
      output = [  
        @own_field,
        @items.map{|x| x.locations},
        @holdings.map{|x| x.locations},
      ].flatten 
      output.push('ELEC') if has_electronic_items? 
      output.uniq
    end
    def has_electronic_items?
      !@elec_items.empty? or !@other_electronic_items.empty?
    end
    def summary_holdings_for(hol_mmsid)
      @summary_holdings.select{|x| x.hol_mmsid == hol_mmsid }.map{|x| x.text}.join(' : ')
    end
    def items_for(hol_mmsid)
      @items.select{|x| x.hol_mmsid == hol_mmsid }
    end
    def finding_aid
      @other_electronic_items.find{|x| x.class.name =~ /FindingAidItem/}
    end
    def not_finding_aid_other_electronic_items
      @other_electronic_items.select{|x| x.class.name !~ /FindingAidItem/}
    end
    def finding_aid?
      !finding_aid.nil?
    end
    private
    def get_sys_control_numbers
      process_tag(['035']) do |f, output|
        output.push(f['a'])
      end
    end
    def get_own_field
      own_field = nil
      @record.each_by_tag(['958', 'OWN']) do |f|
        own_field = f['a']&.upcase
      end
      own_field
    end
    def get_electronic_items
      process_tag('E56') do |f, output|
        next if f['u'].nil?
        output.push(ElectronicItem.for(f))
      end
    end
    def get_other_electronic_items 
      process_tag('856') do |f, output|
        next if f['u'].nil?
        output.push(OtherElectronicItem.for(f))
      end
    end

    def get_summary_holdings
      process_tag('866') do |f, output|
        next if f['8'].nil?
        output.push(SummaryHolding.new(f))
      end
    end
    def get_items
      process_tag('974') do |f, output|
        next if f['8'].nil?
        next if f['b'] == 'ELEC'  # ELEC is mistakenly migrated from ALEPH
        next if f['y']&.match?(/Process Status: (EO|SD|CA|WN|WD|MG|CS)/)
        output.push(AlmaItem.new(f))
      end
    end
    def get_holdings
      process_tag('852') do |f, output|
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
