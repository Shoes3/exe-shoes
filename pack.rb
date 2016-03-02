# run this with cshoes.exe --ruby poc.rb
require 'yaml'
require 'fileutils'
opts = YAML.load_file('ytm.yaml')
here = Dir.getwd
home = ENV['HOME']
appdata =   ENV['LOCALAPPDATA']
appdata  =   ENV['APPDATA'] if ! appdata
GEMS_DIR = File.join(appdata.tr('\\','\/'), 'Shoes','+gem')
puts "DIR = #{DIR}"
puts "GEMS_DIR = #{GEMS_DIR}"
puts "Here = #{here}"

 def rewrite a, before, hsh
    File.open(before) do |b|
      b.each do |line|
        a << line.gsub(/\#\{(\w+)\}/) {
          if hsh[$1] 
            hsh[$1]
          else
            '#{'+$1+'}'
          end
        }
      end
    end
  end
  
toplevel = []
Dir.chdir(DIR) do
  Dir.glob('*') {|f| toplevel << f}
end
exclude = %w(static CHANGELOG.txt  gmon.out README.txt
  samples)
#exclude = []
packdir = 'packdir'
rm_rf packdir
mkdir_p(packdir) # where makensis will find it.
(toplevel-exclude).each do |p|
  cp_r File.join(DIR, p), packdir
end
# remove chipmonk and ftsearch unless requested
rbmm = RUBY_VERSION[/\d.\d/].to_str
exts = opts['include_exts'] # returns []
if  !exts || ! exts.include?('ftsearch')
  puts "removing ftsearchrt.so"
  rm "#{packdir}/lib/ruby/#{rbmm}.0/i386-mingw32/ftsearchrt.so" 
  rm_rf "#{packdir}/lib/shoes/help.rb"
  rm_rf "#{packdir}/lib/shoes/search.rb"
end
if  !exts || ! exts.include?('chipmunk')
  puts "removing chipmunk"
  rm "#{packdir}/lib/ruby/#{rbmm}.0/i386-mingw32/chipmunk.so"
  rm "#{packdir}/lib/shoes/chipmunk.rb"
end
# get rid of some things in lib
rm_rf "#{packdir}/lib/exerb"
rm_rf "#{packdir}/lib/gtk-2.0"
# remove unreachable code in packdir/lib/shoes/ like help, app-package ...
['cobbler', 'debugger', 'irb', 'pack', 'app_package', 'packshoes',
  'remote_debugger', 'winject', 'envgem'].each {|f| rm "#{packdir}/lib/shoes/#{f}.rb" }
  
# copy app contents (file/dir at a time)
app_contents = Dir.glob("#{opts['app_loc']}/*")
app_contents.each do |p|
 cp_r p, packdir
end
#create new lib/shoes.rb with rewrite
newf = File.open("#{packdir}/lib/shoes.rb", 'w')
rewrite newf, 'min-shoes.rb', {'APP_START' => opts['app_start'] }
 
# copy/remove gems - tricksy - pay attention
# remove the Shoes built-in gems if not in the list 
incl_gems = opts['include_gems']
rm_gems = []
Dir.glob("#{packdir}/lib/ruby/gems/#{rbmm}.0/specifications/*gemspec") do |p|
  gem = File.basename(p, '.gemspec')
  if incl_gems.include?(gem)
    puts "Keeping Shoes gem: #{gem}"
    incl_gems.delete(gem)
  else
    rm_gems << gem
  end
end
sgpath = "#{packdir}/lib/ruby/gems/#{rbmm}.0"
# sqlite is a special case so delete it differently - trickery
if !incl_gems.include?('sqlite3')
  spec = Dir.glob("#{sgpath}/specifications/default/sqlite3*.gemspec")
  rm spec[0]
  rm_gems << File.basename(spec[0],'.gemspec')
else
  incl_gems.delete("sglite3")
end
rm_gems.each do |g|
  puts "Deleting #{g}"
  rm_rf "#{sgpath}/specifications/#{g}.gemspec"
  rm_rf "#{sgpath}/extensions/x86-mingw32/#{rbmm}.0/#{g}"
  rm_rf "#{sgpath}/gems/#{g}"
end

# copy requested gems from AppData\Local\shoes\+gems aka GEMS_DIR
incl_gems.delete('sqlite3') if incl_gems.include?('sqlite3')
incl_gems.each do |name| 
  puts "Copy #{name}"
  cp "#{GEMS_DIR}/specifications/#{name}.gemspec", "#{sgpath}/specifications"
  cp_r "#{GEMS_DIR}/gems/#{name}", "#{sgpath}/gems"
end

# now it's time to use makensis on packdir and hope for the best.
puts "make_installer"
mkdir_p "pkg"
#cp_r "VERSION.txt", "#{packdir}/VERSION.txt"
rm_rf "#{packdir}/nsis"
cp_r  "nsis", "#{packdir}/nsis"
cp opts['app_ico'], "#{packdir}/nsis/setup.ico"
newn = File.open("#{packdir}/nsis/#{opts['app_name']}.nsi", 'w')
rewrite newn, "#{packdir}/nsis/base.nsi", {'APPNAME' => opts['app_name'],
  'WINVERSION' => opts['app_version']}
# rewrite "#{TGT_DIR}/nsis/base.nsi", "#{TGT_DIR}/nsis/#{WINFNAME}.nsi"
Dir.chdir("#{packdir}/nsis") do
   system "\"c:\\Program Files (x86)\\NSIS\\Unicode\\makensis.exe\" #{opts['app_name']}.nsi"
  #sh "\"c:\\Program Files (x86)\\NSIS\\makensis.exe\" #{WINFNAME}.nsi" 
end
mv "#{packdir}/nsis/#{opts['app_name']}.exe", '.'
