module UMich
  class Record
    def self.for(record)
      id = record['001'].value
      if id.match?(/\A99.*?6381\Z/)
        AlmaRecord.new(record)
      elsif id.match?(/\A\d{9}\Z/)
        HathiRecord.new(record)
      end
      #ignores ones that don't match
    end
    def initialize(record)
      @record = record
    end
    def id
      id = @record['001'].value
    end
    def record_source
        'unknown'
    end
  end
end

