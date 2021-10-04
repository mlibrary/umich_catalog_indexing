module UMich
  class HathiRecord
    def initialize(record, etas_active = false)
      @record = record
      @items = get_items
      @etas_active = etas_active
    end
    def holding
      {
        "library" => library,
        "items" => @items.map{|x| x.to_h}
      }
    end
    private
    def get_items
      process_tag('974') do |f, output|
        next unless f['u']
        output.push(Item.new(f, @etas_active))
      end
    end
    def process_tag(tag)
      output = Array.new
      @record.each_by_tag(tag) do |f|
        yield(f, output)
      end
      output
    end
    def id
      '11' + @record['001'].value
    end
    def record_source
      'zephir'
    end
    def library
      'HathiTrust Digital Library'
    end
    def availability
      output = Array.new
      output = ['avail_ht_fulltext','avail_online'] if @items.any?{|x| x.access }
      output.push('avail_ht_etas') if @etas_active
      output
    end
    def institution_codes
      ['MIU','MIFLIC']
    end
    def locations
      ['MIU']
    end
    def has_items?
      !@items.empty?
    end

    class Item
      def initialize(field, etas_active = false)
        @field = field
      end
      def id
        @field['u']
      end
      def rights
        @field['r']
      end
      def description
        @field['z']
      end
      def collection_code
        @field['c']
      end
      def source(cc_to_of = ::Traject::TranslationMap.new('ht/collection_code_to_original_from'))
        cc_to_of[collection_code&.downcase]
      end
      def access
        rights.match?(/^(pd|world|ic-world|cc|und-world)/)
      end
      def status(etas = false)
        if access
          "Full text"
        elsif @etas_active
          "Full text available, simultaneous access is limited (HathiTrust log in required)"
        else
          "Search only (no full text)"
        end
      end
      def to_h
        [
          'id','rights','description','collection_code','source','access','status' 
        ].map{|x| [x, public_send(x) ] }.to_h
      end
    
    end
  end
end
