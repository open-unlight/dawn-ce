# server/data/csvにあるデータをインポートする
$:.unshift(File.join(File.expand_path("."), "src"))
require 'find'
require 'pathname'
require 'optparse'
require "sequel"
require "sequel/extensions/inflector"
require 'unlight'
require 'optparse'

if `pwd`.chomp == "/home/unlight/svn/trunk/app/server"
  puts "このスクリプトはここで使用してはいけません"
  exit
end
opt = OptionParser.new

$VER_OVERWRITE = false
$VER_NUMBERING = false
$VER_RESTART = false
over_text = "（ドロップモード：すべて捨てて作り直します。時間がかかりますが正確です ）"
opt.on('-n', '--numbering') {|v|
  $VER_NUMBERING = true
  over_text = "（ナンバリングモード：数値で指定されたファイルのみ更新します）"
}
opt.on('-r', '--restart') {|v|
  $VER_RESTART = true
  over_text = "（再開モード：数値で指定されたファイル以降を更新します）"
}

opt.parse!(ARGV)

if $VER_NUMBERING && $VER_RESTART
  puts "Option n, r は同時に指定出来ません。"
  exit
end

$arg = ARGV.shift
puts "serverに存在するcsvdataでインポートしますか (sb)"+over_text
$arg = gets.chomp
@m_set = []
LANGUAGE_SET = /_tcn$|_en$|_scn$|_kr$|_fr$|_ina$|_thai$/
MESSAGES={ "sb" => "SandBox"}
DATABASES={
  "192.168.1.14:5001"=>"SandBox",
}

def print_file_list
  cnt = 1
  @file_list = { }
  search_dir = "./data/csv/#{$arg}/"
  for i in 0..1 do
    Find.find(search_dir) do |file|
      next unless file =~ /.*\.csv$/
      sig = file.match(/([^\/]+)\.csv/)[1].singularize
      unless @file_list.has_value?(sig)
        @file_list[cnt] = sig
        puts sprintf("%1$2d %2$-30s  %3$2d %4$-30s", cnt-1, @file_list[cnt-1], cnt, @file_list[cnt]) if cnt % 2 == 0
        cnt += 1
      end
    end

    if $arg == "ja"
      break
    else
      search_dir = "./data/csv/ja/"
    end
  end
  puts sprintf("%1$2d %2$-30s", cnt-1, @file_list[cnt-1]) if cnt % 2 == 0
  add_mess = $VER_NUMBERING ? "数値以外の文字で区切って複数入力可。" : ""
  puts "番号を指定指定して下さい。" + add_mess
  if $VER_NUMBERING
    $import_list = gets.chomp.split(/[^\d]+/).map(&:to_i)
  elsif $VER_RESTART
    $restart_point = gets.chomp.to_i
  end
end

def csv_import(dir, local)

  Find.find('./data/csv') do |f|
    next if File.directory?(f)
    next if f =~ /svn/
    next unless f =~ /\/#{dir}\//;
    m = f.match(/([^\/]+)\.csv/)[1].singularize
    next if @m_set.include?(m)
    @m_set << m
    next if $VER_NUMBERING && !$import_list.include?(@file_list.invert[m])
    next if $VER_RESTART && @file_list.invert[m] < $restart_point

    puts "reset #{m}"
    eval("Unlight::#{m}.create_table!")
    puts "create #{m}"
    eval("Unlight::#{m}.unrestrict_primary_key")

    `cp #{f} ./tmp.csv`
    `nkf -wLu --overwrite ./tmp.csv` if ["sb"].include?(local)     #utf-8(LF)
    label = `sed -n "1p" ./tmp.csv`.delete("\"").delete("\n").delete("\r").split(",")
    suffix = ["sb"].include?(local) ? "" : "_" + local

    if Unlight::STORE_TYPE == :sqlite3

      `sed -i -e "1d" ./tmp.csv`

      # 一時表を立てる
      Unlight::DB.drop_table(:import_temp) if Unlight::DB.table_exists?(:import_temp)
      Unlight::DB.create_table(:import_temp, temporary: true, id: false) do |t|
        label.each_with_index { |col_name, i| eval("t.column :#{col_name}, :String") }
      end

      `sqlite3 -separator , ./data/game_dev2.db ".import ./tmp.csv import_temp" > /dev/null 2>&1`
      # 更新日時を都合する
      model_colmuns = label.select{ |c| !c.match(LANGUAGE_SET) }.delete_if { |item| item == "created_at" }
      insert_colmuns = (model_colmuns + ["created_at","updated_at"]).collect!{ |c| c.to_sym }
      dates_colmuns = insert_colmuns.select{ |item| item.match(/_at$/) }.delete_if { |item| item == :created_at || item == :updated_at }
      unless suffix.blank?
        swap_colmuns = label.grep(/#{suffix}$/) { |col_name| col_name.gsub(suffix,"") }
        model_colmuns.collect! { |col_name| swap_colmuns.include?(col_name) ? col_name+suffix : col_name }
      end
      select_colmuns = model_colmuns.collect{ |c| c.to_sym }+[Time.now.utc.strftime("%Y-%m-%d %H:%M:%S %Z"),Time.now.utc.strftime("%Y-%m-%d %H:%M:%S %Z")]

      eval("Unlight::#{m}.insert(#{insert_colmuns}, Unlight::DB[:import_temp].select{#{select_colmuns}})")
      # 空白のdateは空文字で入るのでnullにする
      dates_colmuns.each { |col| eval("Unlight::#{m}.filter(:#{col.to_s}=>'').update(:#{col.to_s}=>nil)") }


    elsif Unlight::STORE_TYPE == :mysql

      table_name = eval("Unlight::#{m}.table_name")
      col_names_str = label.collect { |col_name| col_name.match(LANGUAGE_SET) ? "@"+col_name : "\\`" + col_name + "\\`" }.join(",")
      set_date_exprs = label.grep(/_at$/) { |col_name| "#{col_name}=nullif(#{col_name}, '0000-00-00 00:00:00')" }
      set_swap_exprs = suffix.blank? ? [] : label.grep(/#{suffix}$/) { |col_name| "#{col_name.gsub(suffix,"")}=@#{col_name}" }
      set_expr_str = (set_date_exprs.blank? && set_swap_exprs.blank?) ? "" : "SET " + (set_date_exprs+set_swap_exprs).join(",")

      `mysql --local-infile=1 -u #{Unlight::MYSQL_CONFIG[:user]} -h #{Unlight::MYSQL_CONFIG[:host]} -P #{Unlight::MYSQL_CONFIG[:port]} -p#{Unlight::MYSQL_CONFIG[:password]} #{Unlight::MYSQL_CONFIG[:database]} -e "LOAD DATA LOCAL INFILE './tmp.csv' INTO TABLE #{table_name} FIELDS TERMINATED BY ',' ENCLOSED BY '\\"' IGNORE 1 LINES (#{col_names_str}) #{set_expr_str}"`

      # 更新日時をセット
      eval("Unlight::#{m}.select_all.update(:updated_at=>'#{Time.now.utc.strftime("%Y-%m-%d %H:%M:%S")}', :created_at=>'#{Time.now.utc.strftime("%Y-%m-%d %H:%M:%S")}')")
    end
  end

  csv_import("ja", local) if dir != "ja"
end


unless MESSAGES.key?($arg)
  puts "error!無効な値です"
  exit
end
db_name = Unlight::MYSQL_CONFIG[:host] == "192.168.1.14" ? DATABASES["#{Unlight::MYSQL_CONFIG[:host]}:#{Unlight::MYSQL_CONFIG[:port]}"] : ""
puts "#{MESSAGES[$arg]}版CSVを#{db_name}DBに適用します OK? (y/n)"
exit if gets.chomp != 'y'

print_file_list() if $VER_NUMBERING || $VER_RESTART

csv_import($arg, $arg)

Unlight::DB.drop_table(:import_temp) if Unlight::DB.table_exists?(:import_temp)
`rm -f ./tmp.csv` if File.exist?("./tmp.csv")
