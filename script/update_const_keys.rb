require 'find'
require 'pathname'
require 'optparse'
require 'fileutils'
OUTPUT = false
opt = OptionParser.new

filename = "../server/script/constdata_keys_jp.rb"

opt.parse!(ARGV)

STR = "0123456789abcdefghijklmnoprstuvwxyzABCDEFGHIJKLMNOPRSTUVWXYZ"

def genSecret(len)
  ret = ""
  len.times do
    ret +=STR[rand(STR.size)]
  end
  ret
end


# keyFileを作る
file = Pathname.new(filename)
secret1 = genSecret(48)
secret2 = genSecret(48)

file.open('w') {|f| f.puts DATA.read.gsub('__CONST__',secret1).gsub('__IMAGE__',secret2)}

__END__
CONSTDATA_ENCRYPTKEY = "__CONST__"
IMAGEFILE_HASHKEY = "__IMAGE__"
