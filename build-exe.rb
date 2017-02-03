Shoes.app(title: "Package app in exe", width: 600, height: 550, resizable: false ) do
require("yaml")
	
	PWD = Dir.pwd
	@offside, @edit_box_height = 15, 29 ### box dimmensions
	@options = ["app_name", "app_version", "app_startmenu", "publisher", "website", "app_loc", "app_start", "app_ico", "include_gems", "installer_sidebar_bmp", "installer_header_bmp", "app_installer_ico", "hkey_org", "license" ]
	@ytm = Hash[@options.map {|x| [x, ""]}]
	
	def get_file box
		flow do
			box = edit_box "", width: 400, height: @edit_box_height
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
	
	list = [ @app_name, @app_version, @app_startmenu, @publisher, @website, @app_loc, @app_begin, @app_icon ]
	
	def page1
		@page = 1
		subtitle "Aplication properties", align: "center"
		stack do
			para "App name"
			@app_name = edit_box "used as exe and dir name", width: 200, height: @edit_box_height
			(para "Application version").style(margin_top: @offside)
			@app_version = edit_box "0.99", width: 200, height: @edit_box_height
			(para "Start Menu folder name").style(margin_top: @offside)
			@app_startmenu = edit_box "Can be the same as App name", width: 200, height: @edit_box_height
			(para "Publisher name").style(margin_top: @offside)
			@publisher =  edit_box "", width: 200, height: @edit_box_height
			(para "Website").style(margin_top: @offside)
			@website = edit_box "", width: 200, height: @edit_box_height
		end
	end
	
	def page2
		@page = 2
		subtitle "Aplication source", align: "center"
		stack do
			(para "Application folder").style(margin_top: @offside)
			flow do
				@app_loc = edit_box "", width: 400, height: @edit_box_height
				button "Select folder" do
					@app_loc.text = fix_string(ask_open_folder)
				end
			end
			(para "Starting script name").style(margin_top: @offside)
			@app_begin = edit_box "main.rb", width: 400, height: @edit_box_height
			(para "Exe icon (.ico)").style(margin_top: @offside)
			@app_icon = get_file @app_icon
			
		end
	end
	
	def page3 gem=0, ext=0
		@page = 3;
		g, e = 0, 0
		subtitle "Additional gems", align: "center"
		(para "Add aditional gems").style(top: 100, left: 60)
		@gems = stack top: 110, left: 5 do
			Gem::Specification.each do |gs|
				flow do
					check()
					para("#{gs.name}")
					para("#{gs.version}")
				end
			end
		end		
	end
	
	def page4
		@page = 4
		subtitle "Wizard settings", align: "center"
		stack do
			(para "Wizard side pic (164 x 309) .bmp").style(margin_top: @offside)
		    @setup_side = get_file @setup_side
			(para "Wizard header pic (150 x 57) .bmp").style(margin_top: @offside)
			@setup_head = get_file @setup_head
			(para "Installer icon (.ico)").style(margin_top: @offside)
			@setup_icon = get_file @setup_icon
			(para "Key").style(margin_top: @offside)
			@setup_key = edit_box "mvmanila.com", width: 200, height: @edit_box_height
			(para "NSIS license (leave it as it is)").style(margin_top: @offside)
			@setup_lic = get_file @setup_head
			@setup_lic.text = "#{PWD}/ytm/Ytm.license"
		end
	end
	
	def page5
		subtitle "Config Summary", align: "center"
		flow do
			para @ytm.to_yaml
		end
		@next.remove
		button "Save confg" do
			File.open(ask_save_file, "w") { |f| f.write(@ytm.to_yaml) } 
		end
		button "Deploy", left: 400 	do
			#system{"cshoes.exe --ruby PWD/ytm-merge.rb"}
		end
	end
	
	@pages = [ method(:page1),method(:page2), method(:page3), method(:page4), method(:page5) ]
	@frame = flow margin: 30 do
		@pages[0].call
	end
	
	@next = button "Next", left: 500, top: 500 do
		i=0;
		[ @app_name, @app_version, @app_startmenu, @publisher, @website, @app_loc, @app_begin, @app_icon, @gems, @setup_side, @setup_head, @setup_icon, @setup_key, @setup_lic ].each do |n|
			debug("bag is #{n}")
			begin
				n.nil? || n.text.nil? ? nil : @ytm[@options[i]] = n.text; 
			rescue
				@gems = []
				n.contents.each do |c|
					c.contents[0].checked? ? @gems << c.contents[1].text : nil
				end
				@gems.count > 0 ? @ytm[@options[i]] = @gems : @ytm[@options[i]] = nil
				@gems = nil
			end
			i+=1
		end
		debug("ytm is #{@ytm}")
		turn_page @page, @pages.length, "up"
	end
end
