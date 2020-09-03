# -*- coding: utf-8 -*-
# DBからバックアップファイルを作るスクリプト
# rakeから使う。
$:.unshift(File.join(File.expand_path("."), "src"))
require 'find'
require 'pathname'
require 'optparse'
require "sequel"
require "sequel/extensions/inflector"
require 'unlight'

OUTPUT = false
SEPARATOR = ","
ORIG = true
# 漢字取り出しに使う物だけバックアップ
FILE_LIST = /Achievement\z|ActionCard\z|AvatarItem\z|AvatarPart\z|Channel\z|CharaCardStory\z|CharaCard\z|CharaRecord\z|Charactor\z|Dialogue\z|EquipCard\z|EventCard\z|Feat\z|PassiveSkill\z|QuestLand\z|QuestMap\z|Quest\z|RealMoneyItem\z|TreasureData\z|WeaponCard/




opt = OptionParser.new
# オプションがjの時日本語用のDBに接続L
#
opt.on('-j',"--japanese","日本語版で作る") do|v|
  if v
  end
end

opt.on('-s',"--sandbox","sandboxをのバックアップファイルを作る") do |v|
  if v
    ORIG = false
    #mysql設定
    # SB_MYSQL_CONFIG =  {
    #   :host =>"10.162.66.17",
    #   :port =>3306,
    #   :user => "unlight",
    #   :password =>"ul0073",
    #   :database =>"unlight_db",
    #   :encoding => 'utf8',
    #   :max_connections => 5,
    # }
    # BDB = Sequel.mysql(nil,SB_MYSQL_CONFIG)
    puts "SBDBにした上書き."
  end
end

opt.parse!(ARGV)



def csv_output(dataset,include_column_titles = true)
  n = dataset.naked
  cols = n.columns
  cols.reject!{ |c| (c =~/_en\z|_scn\z|_tcn\z_fr\z/) }
  tsv = ''
  tsv << "#{cols.join(SEPARATOR)}\r\n" if include_column_titles
  n.each do  |r|
    a = ""
    cols.collect{ |c| r[c]}.each{|f| a<< '"'+f.to_s+'"'+(SEPARATOR)}
    a << "\r\n"
    tsv << a
  end
  tsv
end

system("rm ./data/backup/*.csv")

Find.find('./src/model')do |f|
  # モデル以下のファイルを全部require
  next if File.directory?(f)
  Find.prune if f.split("/").size > 4
  req = f.gsub("./src/","")
  m = f.gsub("./src/","")
  # モデル名を取得する
  m = m.gsub("model/","").gsub(".rb","")
  m = m.camelize


  # クラス名から一つずつcsvを取り出す
  next unless  m =~ FILE_LIST
  next if m =~ /^[^A-Z]/
  require "#{req}"
  puts "BackUp #{m}"
  filename = "./data/backup/#{m}_#{Time.now.strftime("%y%m%d")}"
  oldname = "./data/backup/old/#{m}_#{Time.now.strftime("%y%m%d")}"
  doc = <<-END
     Unlight::#{m}.db = BDB unless ORIG
      file = Pathname.new("#{filename}.csv")
      i = 0
      while file.exist?
        ofile = Pathname.new("#{oldname}.csv")
         while ofile.exist?
          ofile = Pathname.new("#{oldname}_"+i.to_s+".csv")
          i+=1
         end
        File.rename(file, ofile)
      end
      if Unlight::#{m}.superclass == Sequel::Model
        puts "Create BackUpFile"+file.to_s
        file.open('w') {|f| f.puts csv_output(Unlight::#{m})}
      end
      END
  #  puts doc if OUTPUT
  eval doc
end
