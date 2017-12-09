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
    opts['hkey_org'] = 'Hackety.org'
	opts['app_ico'] = 'nsis/shoes.ico' unless opts['app_ico']
	opts['app_installer_ico'] = 'nsis/shoes.ico' unless opts['app_installer_ico']
	#opts['license'] = 'ytm/Ytm.license' unless opts['license']
	opts['nsis_name'] = opts['installer_header'] == "" ? opts['app_name'] : opts['installer_header']
	opts['app_startmenu'] = opts['app_name'] unless opts['app_startmenu']
	ruby_ver = RUBY_VERSION[/\d.\d/].to_str
	
    toplevel = []
    Dir.chdir(DIR) { Dir.glob('*') {|f| toplevel << f} }
    exclude = %w(static CHANGELOG.txt cshoes.exe gmon.out README.txt samples)
    packdir = 'packdir'
    rm_rf packdir
    mkdir_p(packdir) # where makensis will find it.
    (toplevel-exclude).each { |p| cp_r File.join(DIR, p), packdir }
	
    # do the license stuff
    licf = File.open("#{packdir}/COPYING.txt", 'w')
    IO.foreach("#{DIR}/COPYING.txt") { |ln| licf.puts ln }  
    licf.close
	
    # we do need some statics for console to work. 
    mkdir_p "#{packdir}/static"
    Dir.glob("#{DIR}/static/icon*.png") { |p| cp p, "#{packdir}/static" }
    opts['app_png'] ? ( cp "#{opts['app_loc']}/#{opts['app_png']}", "#{packdir}/static/app-icon.png" ) : nil

    # remove chipmonk and ftsearch unless requested
    exts = opts['include_exts'] || []
    if  !exts || ! exts.include?('ftsearch')
      puts "removing ftsearchrt.so"
      rm_rf "#{packdir}/lib/shoes/help.rb"
      rm_rf "#{packdir}/lib/shoes/search.rb"
    end
    if  !exts || ! exts.include?('chipmunk')
      puts "removing chipmunk"
      rm "#{packdir}/lib/shoes/chipmunk.rb"
    end
    # get rid of some things in lib
    rm_rf "#{packdir}/lib/exerb"
    rm_rf "#{packdir}/lib/gtk-2.0" if File.exist? "#{packdir}/lib/gtk-2.0"
    # remove unreachable code in packdir/lib/shoes/ like help, app-package ...
    not_needed = ['cobbler', 'debugger', 'shoes_irb', 'pack', 'app_package', 'packshoes', 'remote_debugger', 'winject', 'envgem']
	not_needed.each {|f| rm "#{packdir}/lib/shoes/#{f}.rb" }
    # copy app contents (file/dir at a time)
    app_contents = Dir.glob("#{opts['app_loc']}/*")
    app_contents.each { |p| cp_r p, packdir }
    #create new lib/shoes.rb with rewrite
    newf = File.open("#{packdir}/lib/shoes.rb", 'w')
    rewrite newf, 'min-shoes.rb', {'APP_START' => opts['app_start'] }
    newf.close
    # create a new lib/shoes/log.rb with rewrite
    logf = File.open("#{packdir}/lib/shoes/log.rb", 'w')
    rewrite logf, 'min-log.rb', {'CONSOLE_HDR' => "#{opts['app_name']} Errors"}
    logf.close
    # Delete all gems besides the chosen one //dredknight
	incl_gems = opts['include_gems'] || []
	sgpath = "#{packdir}/lib/ruby/gems/#{ruby_ver}.0"
	Dir.glob("#{sgpath}/specifications/**/*gemspec").each do |p|
		gem = File.basename(p, '.gemspec')
		if !incl_gems.any? {|g| gem.include?(g) } then
			puts "Deleting #{gem}"
			rm_rf "#{sgpath}/specifications/#{gem}.gemspec"
			rm_rf "#{sgpath}/specifications/default/#{gem}.gemspec"
			rm_rf "#{sgpath}/extensions/x86-mingw32/#{ruby_ver}.0/#{gem}"
			rm_rf "#{sgpath}/gems/#{gem}"
		end
	end

    puts "make_installer"
    mkdir_p "pkg"
    rm_rf "#{packdir}/nsis"
    cp_r  "nsis", "#{packdir}/nsis"
    # Icon for installer
    cp opts['app_installer_ico'], "#{packdir}/nsis/setup.ico"
    # change nsis side bar and top images (bmp only)
    sb_img = opts['installer_sidebar_bmp'] 
    sb_img ? ( cp sb_img, "#{packdir}/nsis/installer-1.bmp" ) : nil
    tp_img = opts['installer_header_bmp']
    tp_img ? ( cp tp_img, "#{packdir}/nsis/installer-2.bmp") : nil
    # stuff icon into a new app_name.exe using shoes.exe 
    Dir.chdir(packdir) do |p|
		winico_path = "#{opts['app_ico'].tr('/','\\')}"
		cmdl = "\"..\\portable_apps\\ResHack\\ResHacker.exe\" -modify  shoes.exe, \"#{opts['app_name']}.exe\", \"#{winico_path}\", icongroup,32512,1033"
		if system(cmdl)
			rm 'shoes.exe' if File.exist?("#{opts['app_name']}.exe")
		else
			puts "FAIL: #{$?} #{cmdl}"
		end
    end
    newn = File.open("#{packdir}/nsis/#{opts['app_name']}.nsi", 'w')
    rewrite newn, "#{packdir}/nsis/base.nsi", {
      'APPNAME' => "#{opts['app_name']}",
      'WINVERSION' => opts['app_version'],
	  'STARTMENU_NAME' => opts['app_startmenu'],
      'PUBLISHER' => opts['publisher'],
      'WEBSITE' => opts['website'],
      'HKEY_ORG' => opts['hkey_org'],
	  'NSIS_NAME' => "#{opts['nsis_name']}"
      }
    newn.close
    Dir.chdir("#{packdir}/nsis") do |p|
	  system "\"..\\..\\portable_apps\\NSIS\\App\\NSIS\\makensis.exe\" \"#{opts['app_name']}\".nsi\""
      Dir.glob('*.exe') { |p| mv p, '../../pkg' }
    end
  end
end