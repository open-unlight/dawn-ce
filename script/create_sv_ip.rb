require 'find'
require 'pathname'
require 'optparse'
require 'fileutils'
OUTPUT = false
opt = OptionParser.new

filename = "../server/src/server_ip.rb"

file = Pathname.new(filename)
ip =  `wget -q -O - ipcheck.ieserver.net`

file.open('w') {|f| f.puts DATA.read.gsub('__IP__',ip.chomp)}

__END__

module Unlight
  SV_IP = "__IP__"
end
