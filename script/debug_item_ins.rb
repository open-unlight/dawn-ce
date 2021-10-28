$LOAD_PATH.unshift(File.join(File.expand_path('.'), 'src'))
require 'pathname'
require 'unlight'

module Unlight
  # デバッグ用アイテム追加
  puts 'アイテムを追加しますか？(y/n)'
  answer = gets.chomp
  if %w[y Y yes Yes].include?(answer)

    puts '追加するアバターのIDを指定してください'
    avatar_id = gets.chomp.to_i

    puts '追加するアイテムを指定してください'
    puts 'Format例：[チケット×] => [9,3]'
    list_str = gets.chomp
    list = list_str.split(',')
    item_id = list.shift.to_i
    num = list.shift.to_i

    AT_TIME = Time.now.utc

    import_list = []
    set_list = []
    cnt = 0
    num.times do
      tmp = [avatar_id, item_id, AT_TIME, AT_TIME]
      set_list << tmp
      if set_list.size > 500
        import_list << set_list
        set_list = []
      end
      cnt += 1
      if cnt.positive? && (cnt % 1000).zero?
        puts "ins set cnt:#{cnt} ..."
      end
    end
    unless set_list.empty?
      import_list << set_list
      set_list = []
    end
    columns = %i[avatar_id avatar_item_id created_at updated_at]
    puts "import_list:#{import_list.size}"

    DB.transaction do
      import_list.each do |import_set|
        ItemInventory.import(columns, import_set)
      end
    end
  end
end
