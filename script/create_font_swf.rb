# font
$LOAD_PATH.unshift(File.join(File.expand_path('.'), 'src'))
require 'find'
require 'pathname'
require 'optparse'
OUTPUT = false
opt = OptionParser.new
font_h = 'KozMinPro-Heavy.otf'
font_r = 'KozMinProVI-Regular.otf'

filename = '../client/src/FontLoader.as'
use_char_no = ''
mode_reg = /LOCALE_TCN|LOCALE_SCN|LOCALE_EN|LOCALE_KR|LOCALE_FR|LOCALE_ID|LOCALE_TH/
check_file = nil
end_reg = /;/
all_griph = false

# オプションがsの時sandbox用のURL
#
opt.on('-e', '--english', '英語用') do |v|
  mode_reg = /LOCALE_TCN|LOCALE_SCN|LOCALE_JP|LOCALE_KR|LOCALE_FR/ if v
end

opt.on('-c', '--chinese', '繁体中国語') do |v|
  if v
    font_h = 'wt004.ttf'
    font_r = 'cwming.ttf'
    check_file = 'all_griph_HanWangMingHeavy.txt'
    mode_reg = /LOCALE_EN|LOCALE_JP|LOCALE_SCN|LOCALE_KR|LOCALE_FR|LOCALE_ID|LOCALE_TH/
  end
end

opt.on('-sc', '--schinese', '中国大陸版') do |v|
  if v
    font_h = 'SourceHanSansSC-Heavy.otf'
    font_r = 'SourceHanSansSC-Heavy.otf'
    check_file = 'all_griph_SimpleChineseHeavy.txt'
    mode_reg = /LOCALE_EN|LOCALE_JP|LOCALE_TCN|LOCALE_KR|LOCALE_FR|LOCALE_ID|LOCALE_TH/
  end
end

opt.on('-kr', '--korean', '韓国語') do |v|
  if v
    font_h = 'batang.ttf'
    font_r = 'batang.ttf'
    mode_reg = /LOCALE_TCN|LOCALE_JP|LOCALE_SCN|LOCALE_EN|LOCALE_FR|LOCALE_ID|LOCALE_TH/
  end
end

opt.on('-fr', '--french', 'フランス語用') do |v|
  if v
    mode_reg = /LOCALE_TCN|LOCALE_JP|LOCALE_SCN|LOCALE_KR|LOCALE_EN|LOCALE_ID|LOCALE_TH/
    check_file = 'all_griph_nbr.txt'
    font_h = 'nbr.otf'
    font_r = 'palatino.otf'
    all_griph = true

  end
end

opt.parse!(ARGV)

system('grep -C2 -r  "\".*\"" ../client/src/|grep -v "tmp" |grep -v "#" |grep -v "\.svn"|grep -v -e "writeLog" -e "TAGS"  > ./data/backup/string_constants.txt')

new_const = []
File.open('./data/backup/string_constants.txt') do |file|
  skip = false
  bracket_skip = 0
  bracket_check = false
  file.each_line do |line|
    if line.force_encoding('UTF-8')&.match?(mode_reg)
      skip = true
      bracket_check = true
    else
      if skip || bracket_skip.positive?
        if line.force_encoding('UTF-8')&.match?(end_reg)
          skip = false
        elsif bracket_check && line.force_encoding('UTF-8').include?('{')
          bracket_skip = +1
        elsif line.force_encoding('UTF-8').include?('}') && bracket_skip.positive?
          bracket_skip = -1
        end
        bracket_check = false
      else
        line.gsub!(%r{//.*$}, '')
        new_const << line if line !~ /log.writeLog|TAGS|Embed/ && line =~ /".*"|'.*'/
      end
    end
  end
end
file = Pathname.new('./data/backup/string_constants.txt')
file.open('w') { |f| new_const.each { |a| f.puts a } }

# グリフチェックがある場合
# ======================
if check_file
  check_hash = {}
  File.open("../client/data/#{check_file}") do |file_to_check|
    file_to_check.each_line do |line|
      p line if OUTPUT
      line.scan(/./m) do |ch|
        check_hash[ch] = 'OK'
      end
    end
  end
end
# ======================

# 文字をカウント
h = {}
Find.find('./data/backup') do |f|
  next if File.directory?(f)

  Find.prune if f.split('/').size > 4
  # バックアップ以下のファイルをに対して
  File.open(f) do |backup_file|
    backup_file.each_line do |line|
      p line if OUTPUT
      line.scan(/./m) do |ch|
        puts ch if OUTPUT
        h[ch] = format 'U+%04X', ch.unpack1('U*')
      end
    end
  end
end

error_num = 0
# グリフチェックを行う
if check_file
  h1 = h.dup
  h1.update(check_hash)
  h1.each do |k, v|
    unless v == 'OK'
      puts "This griph undefind #{k},#{v}"
      error_num += 1
    end
  end
end
puts "error font num,#{error_num}."

p h.values.sort! if OUTPUT
p h if OUTPUT
use_char_no = ", unicodeRange='#{h.values.sort!.join(',')}'"
use_char_no = '' if all_griph
file = Pathname.new(filename)
file.open('w') { |f| f.puts DATA.read.gsub('__font_UTF_NO__', use_char_no).gsub('__FONT_H__', font_h).gsub('__FONT_R__', font_r) }
puts "#{h.size}文字を登録しました"

__END__
[Embed(source='../data/__FONT_H__', fontName='minchoB'__font_UTF_NO__)]
private static const Font:Class;
[Embed(source='../data/__FONT_R__', fontName='mincho'__font_UTF_NO__)]
private static const Font2:Class;
[Embed(source='../data/nbr.otf', fontName='bradley')]
private static const Font3:Class;

