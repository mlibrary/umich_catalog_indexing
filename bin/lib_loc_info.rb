require_relative '../lib/umich_utilities/umich_utilities'
require 'yaml'
require 'optparse'
#require 'pry-debugger-jruby'

path = '' 
force = false
OptionParser.new do |opts|
  opts.on("--path PATH") do |x|
    path = x
  end
  opts.on("-f", "--force") do |x|
    force = true
  end
end.parse!

#puts path

if force or !File.exists?(path) or File.stat(path).mtime < Time.now - (60*60*24) #is file older than one day?
  File.open(path, 'w'){|f| f.write UmichUtilities::LibraryLocationList.new.list.to_yaml }
  puts "updated #{path} with Library and Location Info"
else
  puts "#{path} is less than one day old. Did not update"
end
#puts 
