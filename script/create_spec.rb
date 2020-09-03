# spec作成
require 'pathname'
arg = ARGV.shift

filename = "./spec/#{File.basename(arg)}_spec.rb"
classname = File.basename(arg, ".rb")
file = Pathname.new(filename)

unless file.exist?
  file.open('w') {|f| f.puts DATA.read.gsub('__package__',arg).gsub('__ClassName__',classname.capitalize).gsub('__classname__', classname ) }
end

__END__
# __classname__：Specファイル
# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), "spec_help")
$:.unshift(File.join(File.expand_path("."), "src"))

require '__package__'
include Unlight

describe __ClassName__, "がある時は" do
  before(:all) do
    # 初期化
#   @__classname__ = __ClassName__.new
#   @registered = false
  end

  before(:each) do
    # 各exampleについての前処理
  end

  it "****のとき****が成功する" do
#   @registered = @players.register(@test_player_name, "password")
#   @registered.should be_true
  end

  it "*****のとき****すると失敗する" do
#     @players.register(@test_player_name, "password").should be_false
    end
  it "*****のとき****結果は*****" do
#     @players.register(@test_player_name, "password").should == "x"
  end

  after(:each) do
    # 各exampleについての後処理
  end

  after(:all) do
    # 後処理
    @__classname__ = nil
  end

end




