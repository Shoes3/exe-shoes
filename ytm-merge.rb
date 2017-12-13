# run this with cshoes.exe --ruby ytm-merge.rb
require 'yaml'
require_relative 'merge-exe'
opts = ARGV[0].nil? ? YAML.load_file('ytm.yaml') : YAML.load_file(ARGV[0])
here = Dir.getwd
home = ENV['HOME']
appdata = ENV['LOCALAPPDATA']
appdata  = ENV['APPDATA'] if ! appdata
puts "DIR = #{DIR}"
puts "Here = #{here}"

PackShoes::merge_exe opts