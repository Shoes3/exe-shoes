Shoes.app(title: "Package app in exe", width: 600, height: 900, resizable: false ) do
require("yaml")
	
	@edit_box_height, @edit_box_width = 28, 200 ### box dimmensions
	@options = [ 0, 1, 1, 1, 0, 0, 0, 0, 0, 2, 0, 1 ]
	@output = [ "installer_header", "installer_sidebar_bmp", "installer_header_bmp", "app_installer_ico", "app_name", "app_version", "app_startmenu", "publisher", "website", "app_loc", "app_start", "app_ico", "include_gems" ]
	@database = [ @installer_header, @setup_side, @setup_head, @setup_icon , @app_name, @app_version, @app_startmenu, @publisher, @website, @app_loc, @app_begin, @app_icon, @gems = [] ]
	@ytm = Hash[@output.map {|x| [x, ""]}]
		
	def fix_string str
		length, count, new_str = str.length, 0, ""
		str.each_char { |c| c == "\\" ? new_str << "/" : new_str << c }
		return new_str
	end

	def turn_page pg, count, direction = "up"
		direction == "up" ? pg+=1 : pg-=1 
		( pg > 0 && pg <= count ) ? ( @frame.clear do @pages[pg-1].call end ) : nil
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
	
	def page1
		@page = 1
		subtitle "Wizard & application settings", align: "center", top: 10
		stack(left: 40, top: 70, width: 500, height: 700) { background darkgray; border black, strokewidth: 2; button("Help", left: 360, top: 40, width: 100) { help } }
		stack left: 40, top: 110, width: 490, height: 640, scroll: true do
			[ "Installer window name", "Installer side pic (164 x 309) .bmp", "Installer header pic (150 x 57) .bmp", "Installer icon (.ico)", "Application name", "Application version", "Start Menu folder name", "Publisher name", "Website", "Application folder", "Starting script name", "Exe icon (.ico)" ]. each_with_index do | item, i |
				flow height: 60 do
					para item, left: 20, top: 0, height: @edit_box_height
					@database[i] = edit_box "", left: 20, top: 28,  height: @edit_box_height, width: @edit_box_width 
					case @options[i]
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
		stack left: 150, top: 70, width: 300 do
			background darkgray
			border black, strokewidth: 2
			para "Select aditional gems:", align: "center", margin_top: 20, margin_bottom: 20
			Gem::Specification.each do |gs|
				flow margin_left: 50 do
					check(checked: false) { |c| c.checked? ? @gems.push(gs.name) : @gems.delete(gs.name) }
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
			para @ytm.to_yaml
		end
		button("Save confg", displace_left: 40, displace_top: 20, width: 100) { File.open(ask_save_file, "w") { |f| f.write(@ytm.to_yaml) } }
		button("Deploy", displace_left: 360, displace_top: 20, width: 100) do
			File.open("temp", "w") { |f| f.write(@ytm.to_yaml) }
			system("cshoes.exe --ruby ytm-merge.rb temp") 
		end
	end
	
	background dimgray
	@pages = [ method(:page1),method(:page2), method(:page3) ]
	@frame = flow(height: 800, scroll: true) { @pages[0].call }
	
	@next = button "Next", left: 250, top: 800, width: 100 do
		case @page
			when 1 then	@database[0..-2].each_with_index { |n, i| n.nil? || n.text.nil? ? nil : @ytm[@output[i]] = n.text; }
			when 2 then	@ytm[@output.last] = @gems.count == 0 ? nil : @gems; @next.remove
		end
		turn_page @page, @pages.length, "up"
	end
end