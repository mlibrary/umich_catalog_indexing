module UMich
  class AlmaRecord
    class AlmaHolding
      def initialize(field, libLocInfo = ::Traject::TranslationMap.new('umich/libLocInfo').hash)
        @field = field
        @libLocInfo = libLocInfo
      end
      def institution_code
        @field['a']&.upcase
      end
      def hol_mmsid 
        @field['8']
      end
      def callnumber 
        @field['h']
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
      def to_h
        [ 'callnumber','display_name', 'hol_mmsid','info_link','library', 'location',
          'public_note', 'floor_location'
        ].map{|x| [x, public_send(x) ] }.to_h
      end
      def locations
        [institution_code, library, lib_loc].compact
      end
      private
      def lib_loc
        [library, location].join(' ').strip
      end
    end
  end
end
