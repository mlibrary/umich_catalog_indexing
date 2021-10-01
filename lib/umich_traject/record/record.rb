module UMich
  class Record
    def initialize(record)
      @record = record
    end
    def id
      id = @record['001'].value
      #if it's a 9 digit number append 11 to the beginning
      id = '11'+ id if id.match?(/\A\d{9}\Z/)
      id
    end
    def record_source
      if id.match?(/\A11\d{9}\Z/)
        'zephir'
      elsif id.match?(/\A99.*?6381\Z/)
        'alma'
      else
        'unknown'
      end
    end
  end
end

