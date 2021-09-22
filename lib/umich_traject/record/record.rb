module UMich
  class Record
    attr_reader :record
    def initialize(record)
      @record = record
      @elec_items = get_electronic_items 
      @other_electronic_items = get_other_electronic_items
      @summary_holdings = get_summary_holdings
      @holdings = get_holdings
      @items = get_items
    end
    def to_a
      [electronic_items, holdings].flatten
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
    def get_electronic_items
      output = Array.new
      @record.each_by_tag('E56') do |f|
        next if f['u'].nil?
        output.push(ElectronicItem.for(f))
      end
      output
    end
    def get_other_electronic_items 
      output = Array.new
      @record.each_by_tag('856') do |f|
        next if f['u'].nil?
        output.push(OtherElectronicItem.for(f))
      end
      output
    end

    def get_summary_holdings
      output = Array.new
      @record.each_by_tag('866') do |f|
        next if f['8'].nil?
        output.push(SummaryHolding.new(f))
      end
      output
    end
    def get_items
      output = Array.new
      @record.each_by_tag('974') do |f|
        next if f['8'].nil?
        output.push(Item.new(f))
      end
      output
    end
    def get_holdings
      output = Array.new
      @record.each_by_tag('852') do |f|
        next if f['8'].nil?
        next if f['b'] == 'ELEC'
        output.push(Holding.new(f))
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
