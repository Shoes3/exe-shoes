# run this with cshoes.exe --ruby ytm-merge.rb
require 'yaml'
require_relative 'merge-exe'
opts = YAML.load_file('ytm.yaml')
here = Dir.getwd
home = ENV['HOME']
appdata =   ENV['LOCALAPPDATA']
appdata  =   ENV['APPDATA'] if ! appdata
GEMS_DIR = File.join(appdata.tr('\\','\/'), 'Shoes','+gem')
puts "DIR = #{DIR}"
puts "GEMS_DIR = #{GEMS_DIR}"
puts "Here = #{here}"
PackShoes::merge_exe opts
