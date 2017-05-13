require("yaml")
require 'fileutils'

Shoes.app(title: "Package app into exe", width: 600, height: 550, resizable: true) do
	PWD = Dir.pwd
	@offside, @edit_box_height = 15, 20 ### box dimmensions
	#@options = ["app_name", "app_version", "app_startmenu", "publisher", "website",
  #   "app_loc", "app_start", "app_ico", "include_gems", "installer_sidebar_bmp",
  #   "installer_header_bmp", "app_installer_ico", "hkey_org", "license" ]
	@options = ["app_name", "app_version", "publisher", "website",
     "app_loc", "app_start", "app_ico", "include_gems", "installer_sidebar_bmp",
     "installer_header_bmp", "app_installer_ico", "hkey_org", "license"]
	#@ytm = Hash[@options.map {|x| [x, ""]}]
	@values = Hash[@options.map {|x| [x, ""]}]
  @values['include_gems'] = []
  rbmm = RUBY_VERSION[/\d.\d/].to_str
  appdata =  ENV['LOCALAPPDATA']
  appdata =  ENV['APPDATA'] if ! appdata
  GEMS_DIR = File.join(appdata.tr('\\','\/'), 'Shoes','+gem')
  @gs_filep = {} # hash of 'gem.name-version' => filesystem .gemspec location

	background dimgray
  def load_yaml 
    fl = ask_open_file
    if fl
      opts = YAML.load_file(fl)
      opts.each {|k, v| @values[k] = v}
      # because shoes/script has already got page1 widgets on screen we need to change them
      # sigh. 
      @app_name.text = @values['app_name']
      @app_version.text = @values['app_version']
      @publisher.text = @values['publisher']
      @website.text = @values['website']
      $stderr.puts "gems: #{@values['include_gems']}"
      # strip off '-x86-mingw32' 
      @values['include_gems'].each do |g|
        g.gsub!(/\-x86\-mingw32/, '')
      end
      $stderr.puts "use this: #{@values['include_gems']}"
    end
  end
  
  def find_nsis
    # ask_open_file returns:
    #  C:\Program Files (x86)\NSIS\Unicode\makensis.exe 
    # needs to become something like below
    cmdr = "\"C:\\Program Files (x86)\\Resource Hacker\\ResourceHacker.exe\" -modify  shoes.exe, #{opts['app_name']}.exe, #{winico_path}, icongroup,32512,1033"
    cmdl = "\"C:\\Program Files (x86)\\NSIS\\Unicode\\makensis.exe\" #{opts['app_name']}.nsi\""
  end
  
  def gsfl_add gspath
    fn = File.basename(gspath, ".gemspec")
    newfn = fn.gsub(/\-x86-mingw32/, '')
    @gs_filep[newfn] = gspath
    #$stderr.puts "hash this: #{newfn} => #{gspath}"
  end
  
	def get_file box, marg
		flow do
			box = edit_box "", width: 300, height: @edit_box_height, margin_left: marg
			button "Select file" do
				 box.text = fix_string(ask_open_file)
			end
		end
		return box
	end
	
	def fix_string str
		length, count, new_str = str.length, 0, ""
		for count in 0..length-1
			str[count] == "\\" ? new_str << "/" : new_str << str[count]
		end
		return new_str
	end

	def turn_page pg, count, direction = "up"
		direction == "up" ? pg+=1 : pg-=1 
		( pg > 0 && pg <= count ) ? ( @frame.clear do @pages[pg-1].call end ) : nil
	end
		
	def page1
		@page = 1
		subtitle "Application properties", align: "center"
#		stack left: 128, top: 70, width: 0.5, height: 400 do
#		stack width: 0.8, height: 400 do
    stack height: 350 do
			background darkgray
			border black, strokewidth: 2
			para "App name", margin_left: 32, margin_top: 10
			@app_name = edit_line @values['app_name'], margin_left: 32,
          tooltip: "This and the SubName string will be used to name the installer File " do
        @values['app_name'] = @app_name.text
      end
			para "Application Subname", margin_top: 10, margin_left: 32
			@app_version = edit_line @values['app_version'], margin_left: 32,
          tooltip: "This is a string that is appended to App Name to name the installer file a hypthen will will be inserted" do
        @values['app_version'] = @app_version.text
      end
      
			para "Publisher name", margin_top: 10, margin_left: 32
      if !@values['publisher']
        @values['publisher'] = "My name here"
      end
			@publisher =  edit_line @values['publisher'], margin_left: 32,
          tooltip: "Your compony or org name" do
          @values['publisher'] = @publisher.text
      end
      
			para "Website", margin_top: 10, margin_left: 32
			@website = edit_line @values['website'], margin_left: 32,
          width: 0.8, tooltip: "url to your website" do
        @values['website'] = @website.text
      end
		end
	end
	
	def page2
		@page = 2
		subtitle "Application source", align: "center"
		stack  height: 280, width: 1.0 do
			background darkgray
			border black, strokewidth: 2
			para "Starting script name", margin_top: 10, margin_left: 32
      flow do
			  @app_start = edit_line @values['app_start'], width: 300, margin_left: 32,
            margin_right: 4,
            tooltip: "The first script to run for your Shoes app"
        button "Select .rb file" do
          longfn = ask_open_file
          @app_start.text = File.basename(longfn)
          @values['app_start'] = @app_start.text
          appdir = File.dirname(longfn)
          @app_loc.text = appdir
          @values['app_loc'] = appdir
        end
      end
			#para "Application folder", margin_top: 10, margin_left: 32
			para "Application folder", margin_left: 32
      @app_loc = edit_line @values['app_loc'], width: 300, margin_left: 32, 
          tooltip: "points to the top level folder of your Shoes app", state: "disabled"  
			para "Exe icon (.ico)", margin_left: 32
			flow do
			  @app_icon = edit_line @values['app_ico'], width: 300, margin_left: 32,
            margin_right: 4,
            tooltip: "The Window app icon for your Shoes app"
        button "Select .ico" do
          @app_icon.text = fix_string(ask_open_file)
          @values['app_ico'] = @app_icon.text
        end
      end
		end
	end
	
	def page3
		@page = 3
		subtitle "Gems to include", align: "center"
		@gems = stack left: 120, top: 70, width: 300 do
			background darkgray
			border black, strokewidth: 2
			para "Add gems", align: "center", margin_top: 20, margin_bottom: 20
      rbmm = RUBY_VERSION[/\d.\d/].to_str
      gspec = {}    # not your normal hash, see the check click proc below
      Dir.glob("#{DIR}/lib/ruby/gems/#{rbmm}.0/specifications/*.gemspec") do |gs_fl|
        gsfl_add gs_fl
      end
      Dir.glob("#{GEMS_DIR}/specifications/*gemspec") do |gs_fl|
        gsfl_add gs_fl
      end
      Gem::Specification.each do |gs|        
        gs_full = "#{gs.name}-#{gs.version}"
        #gs_full = File.basename(gs_fl, ".gemspec")
        #$stderr.puts "basename: #{gs_full}"
				flow margin_left: 50 do
				  c =	check do |s| 
            # user clicked proc
            g = gspec[s]
            if s.checked? 
              $stderr.puts "add #{g.name}"
              @values['include_gems'].push(gs_full)
            else
              $stderr.puts "delete #{g.name}"
              @values['include_gems'].delete(gs_full)
            end
          end
          gspec[c] = gs_full     
					para("#{gs_full}")
          idx = @values['include_gems'].find_index(gs_full) 
          if idx 
            $stderr.puts "check #{gs_full}: #{idx}" 
            c.checked = true
          end
				end
			end			
		end	
		start do 
      @gems.style( height: @gems.height + 20)
    end
	end
	
	def page4 
		@page = 4
		subtitle "NSIS Unique Settings", align: "center"
		stack  height: 380 do
			background darkgray
			border black, strokewidth: 2
			para "Installer sidebar (164 x 309) .bmp", margin_left: 32
      flow do
			  @setup_side = edit_line @values['installer_sidebar_bmp'], width: 300,
          margin_left: 32, margin_right:4,
          tooltip: "The sidebar image (old bmp) for the installer"
			  button "Select file" do
          @setup_side.text = ask_open_file
          @values['installer_sidebar_bmp'] = @setup_side.text
			  end
		  end
			para "Installer header pic (150 x 57) .bmp", margin_left: 32
      flow do
			  @setup_head = edit_line @values['installer_header_bmp'], width: 300, 
          margin_left: 32, margin_right: 4,
          tooltip: "The header image for the installer"
			  button "Select file" do
          @setup_head.text = ask_open_file
          @values['installer_header_bmp'] = @setup_head.text
			  end
		  end
      para "Installer's icon (.ico)", margin_left: 32
      flow do
			  @setup_icon = edit_line @values['app_installer_ico'], width: 300, 
          margin_left: 32,  margin_right: 4,
          tooltip: "The icon for the #{@values['app_name']}-#{@values['app_version']}.exe file - NOT the icon for app desktop"
          
			  button "Select file" do
          @setup_icon.text = ask_open_file
          @values['app_installer_ico'] = @setup_icon.text
			  end
		  end
      para "hkey_org", margin_left: 32
      if ! @values['hhey_org'] 
        @values['hkey_org'] = "mvmanila.com"
      end
			@setup_key = edit_line @values['hkey_org'], width: 300, margin_left: 32,
          tooltip: "don't change this unless you know what it means" do
        edit_line @values['hkey_org'] = @setup_key.text
      end
			para "Pre-pend to License", margin_left: 32
      flow do
        @setup_lic = edit_line @values['license'], width: 300,margin_left: 32,
          margin_right: 4,
          tooltip: "prepend the contents to the Shoes LICSENSE.txt file\n \
Will be shown to the User at install time, so make it pretty"
        button "Select file" do
          @setup_lic.text = ask_open_file
          @values['license'] = @setup_lic.text
        end
      end
		end
	end
	
	def page5
    @page = 5
		subtitle "Config Summary", align: "center"
    # need to clean up/rewrite the gem names vs path to .gemspec
    # args depends on what merge-exe.rb deals with - Subject to change. 
    nv = @values.dup
    nv['include_gems'] = []
    @values['include_gems'].each do |g|
      path = @gs_filep[g]
      if path
        #$stderr.puts "looking for #{g} found #{path}"
        nv['include_gems'] << File.basename(path, '.gemspec')
      else
        alert "Gem not available #{g} check your .yaml"
        #$stderr.puts "Gem not available #{g}"
      end
    end
    # Find the resource hacker and makensis exe's
    # A tricky file name to deal with. shell vs ruby on windows with spaces
    # another trick is in merge.exe
    #sh_deflt_cmdr = "\"C:\\Program Files (x86)\\Resource Hacker\\ResourceHacker.exe\""
    sh_deflt_cmdr = "C:\\Program Files (x86)\\Resource Hacker\\ResourceHacker.exe"
    nv['reshack_loc'] = sh_deflt_cmdr unless nv['reshack_loc']
    have_rez = File.exist? nv['reshack_loc']
    $stderr.puts "have_rez: #{nv['reshack_loc']}: #{have_rez}"
    
    #sh_deflt_cmdl = "\"C:\\Program Files (x86)\\NSIS\\Unicode\\makensis.exe\""
    sh_deflt_cmdl = "C:\\Program Files (x86)\\NSIS\\Unicode\\makensis.exe"
    nv['nsis_loc'] = sh_deflt_cmdl unless nv['nsis_loc']
    have_nsis = File.exist? nv['nsis_loc']
    $stderr.puts "have nsis #{nv['nsis_loc']}: #{have_nsis}"
    stack do
      flow do 
        if ! have_rez
          rezbtn = button "Resource Hacker" do
            rp = ask_open_file
            if rp && File.exist?(rp)
              nv['reshack_loc'] = rp
              @yaml_dsp.clear { para nv.to_yaml, stroke: white}
              rezbtn.remove
            else
              alert "You must have \"Resource Hacker\" installed, Do not continue!" 
            end
          end
        end
        if ! have_nsis
          nsbtn =button "NSIS Unicode" do
            np = ask_open_file
            if np && File.exist?(np)
              nv['nsis_loc'] = np
              @yaml_dsp.clear { para nv.to_yaml, stroke: white}
              nsbtn.remove
            else
              alert "You must have \"NSIS Unicode\" installed, Do not continue!" 
            end
         end
        end
  		  button "Save confg" do
	    		File.open(ask_save_file, "w") { |f| f.write(nv.to_yaml) } 
    		end
  		  @go_btn = button "Create .exe" 	do
          require_relative 'merge-exe'
          @go_btn.state = "disabled"
          Shoes.terminal
          # clever people could create a new shoes window/app (different OS thread)
          # with a progess bar in it, maybe a status message area and pass something
          # into an optional arg to Package::merge_exe that it can call to update the
          # the progress widget and the status text. Like the Gem install does. 
          PackShoes::merge_exe nv
          @go_btn.state = nil # nil enables button - legacy
          # create a quit button to let user know that it's time to end this.
	  	  end
      end
    end
    # display yaml
    stack do
		  @yaml_dsp = flow do # depends on yaml having nl's embedded
			  para nv.to_yaml, stroke: white
		  end
    end
	end
	
  # create the outer gui - button bar, panel for page(n) content
	@pages = [ method(:page1),method(:page2), method(:page3), method(:page4), method(:page5) ]
  stack width: 0.9 do
    @btnbar = flow margin: 30 do
      @load_btn = button "Load yaml", tooltip: "existing yaml configuration" do
        load_yaml
        #@pages[0].call
      end
      button 'Next' do
        # @page range 1..5 - call index is 0..4
        np = @page + 1
        np = @pages.size if np > @pages.size
        @frame.clear { @pages[np-1].call }
      end
      button 'Previous' do
        # @page range 1..5 - call index is 0..4
        np = @page - 1
        np = 1 if np < 1
        @frame.clear { @pages[np-1].call }
      end
    end
    #@frame = flow margin: 0.05 do #, width: 0.9 do
    @frame = stack margin: 16 do
      @pages[0].call
    end
#    @next = button "Next", left: 500, top: 500 do
#      i=0;
#  #		[ @app_name, @app_version, @app_startmenu, @publisher, @website, @app_loc, @app_begin, 
#  #      @app_icon, @gems, @setup_side, @setup_head, @setup_icon, @setup_key, @setup_lic ].each do |n|
#      [ @app_name, @app_version, @publisher, @website, @app_loc, @app_begin, 
#        @app_icon, @gems, @setup_side, @setup_head, @setup_icon, @setup_key, @setup_lic ].each do |n|
#        begin
#          n.nil? || n.text.nil? ? nil : @values[@options[i]] = n.text; 
#        rescue
#          #$stderr.puts "rescued #{n.inspect}"
#          #@gems = []
#          #n.contents[3..-1].each do |c|
#          #	c.contents[0].checked? ? @gems << c.contents[1].text : nil
#          #end
#          #@gems.count > 0 ? values[@options[i]] = @gems : @values[@options[i]] = nil
#          #@gems = nil
#        end
#      i+=1
#      end
#      #debug("ytm is #{values}")
#      turn_page @page, @pages.length, "up"
#    end
  end
end
