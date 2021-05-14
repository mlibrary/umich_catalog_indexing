require_relative '../ht_secure_data'
require 'sequel'

module HathiTrust
  module DBH
    extend HathiTrust::SecureData
    DB = Sequel.connect("jdbc:mysql://#{db_machine}/#{db_db}?user=#{db_user}&password=#{db_password}&useTimezone=true&serverTimezone=UTC")
  end

  module DBH_overlap
    extend HathiTrust::HTOverlap
    DB = Sequel.connect("jdbc:mysql://#{db_machine}/#{db_db}?user=#{db_user}&password=#{db_password}&useTimezone=true&serverTimezone=UTC")
  end

end

