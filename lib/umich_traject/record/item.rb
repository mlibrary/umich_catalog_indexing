module UMich
  class Record
    class Item
      attr_reader :record
      def initialize(field, libLocInfo = ::Traject::TranslationMap.new('umich/libLocInfo').hash)
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
      def to_h
        ['barcode','callnumber','can_reserve','description','display_name','info_link',
         'inventory_number','item_id','item_policy','library','location','permanent_library',
         'permanent_location','process_type','public_note','temp_location'
        ].map{|x| [x, public_send(x) ] }.to_h
      end

      private
      def lib_loc
        [library, location].join(' ').strip
      end
    end
  end
end
