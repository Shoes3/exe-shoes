Shoes.app(title: "Package app in exe", width: 600, height: 900, resizable: false ) do
require("yaml")
	
	@edit_box_height, @edit_box_width = 28, 200 ### box dimmensions
	@options = [ 0, 1, 1, 1, 0, 0, 0, 0, 0, 2, 0, 1 ]
	@output = [ "installer_header", "installer_sidebar_bmp", "installer_header_bmp", "app_installer_ico", "app_name", "app_version", "app_startmenu", "publisher", "website", "app_loc", "app_start", "app_ico", "include_gems" ]
	@database = [ @installer_header, @setup_side, @setup_head, @setup_icon, @app_name, @app_version, @app_startmenu, @publisher, @website, @app_loc, @app_begin, @app_icon, @gems = [] ]
	@values = Hash[@output.map {|x| [x, ""]}]
	@values['include_gems']	= []
	
	def fix_string str
		length, count, new_str = str.length, 0, ""
		str.each_char { |c| c == "\\" ? new_str << "/" : new_str << c }
		return new_str
	end

	def turn_page direction = "up"
		direction == "up" ? @page+=1 : @page-=1 
		( @page > 0 && @page <= @pages.length ) ? ( @frame.clear { @pages[@page-1].call } ) : nil
	end
	
	def help
		@other_win = window tittle:"Exe builder help" do
			tagline "When installing the app", align: "center"
			image "gui_files/Wizard options.png", left: 10, top: 35, width: 280, height: 240 
			image "gui_files/Wizard options2.png", left: 300, top: 35, width: 280, height: 240 
			tagline "When using the app", align: "center", top: 280
			image "gui_files/exe options.png", left: 50, top: 310, width: 50
			para "<- App icon", left: 100, top: 325
			para "<- App name", left: 100, top: 362
		end
	end
	
	def load_yaml 
    fl = ask_open_file
		if fl
			##loading values from yaml into app vars
		    opts = YAML.load_file(fl)
		    opts.each {|k, v| @values[k] = v}
			##updating text on all fields at page1
			@database.each_with_index { |d, i| d.text = @values["#{@output[i]}"] unless d.kind_of?(Array) }
		end
	end
	
	def page1
		@page = 1
		
		subtitle "Wizard & application settings", align: "center", top: 10
		stack(left: 40, top: 70, width: 500, height: 750) do
			background darkgray;
			border black, strokewidth: 2; 
			button("Help", left: 350, top: 15, width: 80) { help }
			button("Load yaml", left: 65, top: 15, width: 80, tooltip: "existing yaml configuration") { load_yaml }
			line(30,55,470,55)
		end
		stack left: 40, top: 170, width: 490, height: 640, scroll: true do
			[ "Installer window name",    #### arranged the array vertically to make troubleshooting page 1 managable
			"Installer side pic (164 x 309) .bmp",
			"Installer header pic (150 x 57) .bmp",	
			"Installer icon (.ico)",
			"Application name",
			"Application version",
			"Start Menu folder name",
			"Publisher name",
			"Website",
			"Application folder",
			"Starting script name",
			"Exe icon (.ico)" ].each_with_index do | item, i |
				flow height: 60 do
					para item, left: 20, top: 0, height: @edit_box_height
					@database[i] = edit_line @values[@output[i]], left: 20, top: 28, height: @edit_box_height, width: @edit_box_width do
						@values[@output[i]]=@database[i].text
					end
					case @options[i] ## adding ask_folder, ask_file boxes where needed
						when 1 then button("Select file", left: 20 + @edit_box_width, top: 27, width: 100) { @database[i].text = fix_string(ask_open_file) }
						when 2 then button("Select folder", left: 20 + @edit_box_width, top: 27, width: 100) { @database[i].text = fix_string(ask_open_folder) }
					end					
				end
			end
		end
	end
	
	def page2
		@page = 2
		subtitle "Manage gems", align: "center", top: 5
		stack left: 100, top: 70, width: 400 do
			background darkgray
			border black, strokewidth: 2
			line(30,55,380,55)
			para "Select aditional gems:", align: "center", margin_top: 70, margin_bottom: 20
			Gem::Specification.each do |gs|
				flow margin_left: 50 do
					check(checked: @values['include_gems'].include?(gs.name) ? true : false ) do |c|
						c.checked? ? @values['include_gems'].push(gs.name) : @values['include_gems'].delete(gs.name)
					end
					para("#{gs.name} #{gs.version}")
				end
			end			
		end
	end

	def page3
		subtitle "Config Summary", align: "center", top: 5
		flow left: 50, top: 80, width: app.width - 100 do
			background darkgray
			border black, strokewidth: 2
			values_exist = {}
			@values.each do |k, v|
				if v != "" and v != nil then
					values_exist["#{k}"] = v
				end
			end
			para "#{values_exist.to_yaml}"
		end
		button("Save confg", displace_left: 40, displace_top: 20, width: 100) { File.open(ask_save_file, "w") { |f| f.write(@values.to_yaml) } }
		button("Deploy", displace_left: 360, displace_top: 20, width: 100) do
			File.open("temp", "w") { |f| f.write(@values.to_yaml) }
			system("cshoes.exe --ruby values-merge.rb temp") 
		end
	end
	
	background dimgray
	@pages = [ method(:page1),method(:page2), method(:page3) ]
	@frame = flow(height: 800, scroll: true) { @pages[0].call }
	
	@previous = button "Previous", left: 200, top: 85, width: 80 do
		turn_page "down"
		@next.show
		@page == 1 ? @previous.hide : nil
	end
	start { @previous.hide }
	@next = button "Next", left: 295, top: 85, width: 80 do
		turn_page "up"
		@previous.show
		@page == @pages.length ? @next.hide : nil
	end
	@previous.hide
end