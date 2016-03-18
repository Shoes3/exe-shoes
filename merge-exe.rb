
module PackShoes
 require 'fileutils'
 def PackShoes.rewrite a, before, hsh
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
  
  def PackShoes.merge_exe opts
    # setup defaults if not in the opts
    opts['publisher'] = 'shoerb' unless opts['publisher']
    opts['website'] = 'http://shoesrb.com/' unless opts['website']
    opts['hkey_org'] = 'Hackety.org' unless opts['hkey_org']
    toplevel = []
    Dir.chdir(DIR) do
      Dir.glob('*') {|f| toplevel << f}
    end
    exclude = %w(static CHANGELOG.txt cshoes.exe gmon.out README.txt
      samples)
    #exclude = []
    packdir = 'packdir'
    rm_rf packdir
    mkdir_p(packdir) # where makensis will find it.
    (toplevel-exclude).each do |p|
      cp_r File.join(DIR, p), packdir
    end
    # do the license struff
    licf = File.open("#{packdir}/COPYING.txt", 'w')
    if opts['license'] && File.exist?(opts['license'])
      IO.foreach(opts['license']) {|ln| licf.puts ln}
    end
    IO.foreach("#{DIR}/COPYING.txt") {|ln| licf.puts ln}  
    licf.close
    # we do need some statics for console to work. 
    mkdir_p "#{packdir}/static"
    Dir.glob("#{DIR}/static/icon*.png") {|p| cp p, "#{packdir}/static" }
    if opts['app_png']
      cp "#{opts['app_loc']}/#{opts['app_png']}", "#{packdir}/static/app-icon.png"
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
    rm_rf "#{packdir}/lib/gtk-2.0" if File.exist? "#{packdir}/lib/gtk-2.0"
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
    newf.close
    # create a new lib/shoes/log.rb with rewrite
    logf = File.open("#{packdir}/lib/shoes/log.rb", 'w')
    rewrite logf, 'min-log.rb', {'CONSOLE_HDR' => "#{opts['app_name']} Errors"}
    logf.close
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

    puts "make_installer"

    mkdir_p "pkg"
    #cp_r "VERSION.txt", "#{packdir}/VERSION.txt"
    rm_rf "#{packdir}/nsis"
    cp_r  "nsis", "#{packdir}/nsis"
    # Icon for installer
    cp opts['app_installer_ico'], "#{packdir}/nsis/setup.ico"
    # change nsis side bar and top images (bmp only)
    sb_img = opts['installer_sidebar_bmp'] 
    if sb_img
     cp sb_img, "#{packdir}/nsis/installer-1.bmp"
    end
    tp_img = opts['installer_header_bmp']
    if tp_img 
     cp tp_img, "#{packdir}/nsis/installer-2.bmp"
    end
    # stuff icon into a new app_name.exe using shoes.exe 
    Dir.chdir(packdir) do |p|
      winico_path = "#{opts['app_ico'].tr('/','\\')}"
      cmdl = "\"C:\\Program Files (x86)\\Resource Hacker\\ResourceHacker.exe\" -modify  shoes.exe, #{opts['app_name']}.exe, #{winico_path}, icongroup,32512,1033"
      #puts cmdl
      if system(cmdl)
        rm 'shoes.exe' if File.exist?("#{opts['app_name']}.exe")
      else 
        puts "FAIL: #{$?} #{cmdl}"
      end
    end
    newn = File.open("#{packdir}/nsis/#{opts['app_name']}.nsi", 'w')
    rewrite newn, "#{packdir}/nsis/base.nsi", {
      'APPNAME' => opts['app_name'],
      'WINVERSION' => opts['app_version'],
      "PUBLISHER" => opts['publisher'],
      "WEBSITE" => opts['website'],
      "HKEY_ORG" => opts['hkey_org']
      }
    newn.close
    Dir.chdir("#{packdir}/nsis") do |p|
      system "\"C:\\Program Files (x86)\\NSIS\\Unicode\\makensis.exe\" #{opts['app_name']}.nsi\""
      Dir.glob('*.exe') { |p| mv p, '../../pkg' }
    end
  end
end
