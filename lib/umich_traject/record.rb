module UMich
  class Record
    attr_reader :record
    def initialize(record)
      @record = record
    end
    def summary_holdings
      output = Array.new
      @record.each_by_tag('866') do |f|
        next if f['8'].nil?
        output.push(Holding.new(f))
      end
      output
    end
    def items
      output = Array.new
      @record.each_by_tag('974') do |f|
        next if f['8'].nil?
        output.push(Holding.new(f))
      end
      output
    end
    def holdings
      output = Array.new
      @record.each_by_tag('852') do |f|
        next if f['8'].nil?
        next if f['b'] == 'ELEC'
        output.push(Item.new(f))
      end
      output
    end

    class Item
      attr_reader :record
      def initialize(field, libLocInfo = Traject::TranslationMap.new('umich/libLocInfo'))
        @field = field
        @libLocInfo = libLocInfo
      end
      def can_reserve
        ['CLEM','BENT','SPEC'].include?(library) ? true : false
      end
      def barcode
        @field['a']
      end
      def hol_mmsid 
        @field['8']
      end
      def library 
        #current library
        @field['b']
      end
      def location 
        #current location
        @field['c']
      end
      def info_link
        @libLocInfo.dig(lib_loc,"info_link")
      end
      def display_name
        @libLocInfo.dig(lib_loc,"name")
      end



      def permanent_library
        @field['d']
      end
      def permanent_location
        @field['e']
      end
      def temp_location
        library == permanent_library && location == permanent_location ? false : true
      end
      def callnumber
        @field['h']
      end
      def public_note
        @field['n']
      end
      def process_type
        @field['t']
      end
      def item_policy
        @field['p']
      end
      def description
        @field['z']
      end
      def inventory_number
        @field['i']
      end
      def item_id
        @field['7']
      end

      private
      def lib_loc
        [library, location].join(' ').strip
      end
    end
    class SummaryHolding 
      def initialize(field)
        @field = field
      end
      def hol_mmsid
        @field['8']
      end
      def text
        @field['a'].join(' : ')
      end
    end
    class Holding
      def initialize(field, libLocInfo = Traject::TranslationMap.new('umich/libLocInfo'))
        @field = field
        @libLocInfo = libLocInfo
      end
      def hol_mmsid 
        @field['8']
      end
      def library 
        #current library
        @field['b']
      end
      def location 
        #current location
        @field['c']
      end
      def info_link
        @libLocInfo.dig(lib_loc,"info_link")
      end
      def display_name
        @libLocInfo.dig(lib_loc,"name")
      end
      def public_note
        @field['z']
      end
      def floor_location
        UMich::FloorLocation.resolve(library, location, callnumber) if callnumber
      end
      private
      def lib_loc
        [library, location].join(' ').strip
      end
    end
  end
end
