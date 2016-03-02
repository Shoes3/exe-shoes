#!/usr/bin/env ruby
# Copyright 2009. Cecil Coupe (ccoupe@cableone.net)
# May not be sold or offered to customers without a liscense.
# These arbitrary terms subject to negotiation
#
# Most people can just use it. Share it. Link to it. Or not. Don't sell it.
#
# There's your liscence. 
require 'date'
require 'csv'
require 'net/http'
require 'rubyserial'

$dateToday = DateTime.now()
#$dateTodayMDY = "#{$dateToday.month}/#{$dateToday.day}/#{$dateToday.year}"
$dateTodayMDY = sprintf("%02d/%02d/%04d",$dateToday.month, $dateToday.day,
						$dateToday.year)

# flag when the collection has been modified 
$tainted = false
# For better or worse, all properties are text
# All percentages are "0.xx" strings. For display they need even more
# string slinging

class Security
	attr_accessor :symbol, :purchaseDate, :matureDate, :purchasePrice,
		:maturityPrice , :dividend, :freq, :nextDivDate, :couponRate,
		:currentYield, :ytm, :cagr, :disc
	
	def initialize(sym = 'symbol')
		@symbol = sym
		@purchaseDate = $dateTodayMDY
		@matureDate = '12/31/2015'
		@purchasePrice = '21.00'
		@maturityPrice = '25.00'
		@dividend = '0.375'
		@freq = '4'
		@nextDivDate = '03/25/2009'
		@couponRate = '0.0'
		@currentYield = '0.0'
		@ytm = '0.0'
		@cagr = '0.0'
		@disc = '0.02'
	end
	
		
	def compute
		# coupon yield (or rate)  (face value)
		mpr = @maturityPrice.to_f
		freq = @freq.to_i
		div = @dividend.to_f
		cpy = (div*freq)/mpr
		@couponRate = sprintf("%2.04f",cpy)
		
		# current yield (current price)
		curpr = @purchasePrice.to_f
		cury = (div*freq)/curpr
		@currentYield = sprintf("%2.04f",cury)
		
		# quick cut at YTM for GUI testing only
		std = Date.parse(@purchaseDate)
		exdt = Date.parse(@nextDivDate)
		if exdt < std
			# best guess
			exdt += (365/freq).to_i
		end
		# calculate the days from purchars/now to the first div
		gap = exdt - std
		# iterate to collect the number of dividends and days
		# discount/grow the future dividends that by whatever rate you like.
		disc = @disc.to_f
		ndays = 0
		ndiv = 0
		recv = 0.0
		inc= (365/freq).to_i
		endd = Date.parse(@matureDate)
		while exdt <  endd
			ndiv += 1
			recv += div * (1+(disc/freq))
			exdt += inc
		end
		
		ilen = endd - std
		nyrs = ilen/365.25
		# reduce the end price by the discount rate
		
		prg = (mpr - curpr) + recv
		puts "#{ndiv} Dividends produced $#{recv} plus price gain => $#{prg}"
		puts "That's #{ilen} days until maturity or #{nyrs} years"
		# the next line is the YTM appoximation formula
		ytm = ((div*freq)+((mpr-curpr)/nyrs))/((mpr+curpr)/2)
		ymult = (mpr+recv)/curpr
		cagr= (ymult**(1.0/nyrs))-1.0
		puts "ymult = #{ymult} CAGR = #{cagr}"
		@ytm = sprintf("%2.04f",ytm)
		@cagr = sprintf("%2.04f",cagr)
	end
	# returns a fixed width string for display/debug purposes
	def format
		return sprintf("%-10s %8s %8.02f%% %8.02f%% %8.02f%%",@symbol, 
				@matureDate,@currentYield.to_f*100.0,
				@ytm.to_f*100.0, @cagr.to_f*100.0)
	end
	
end


class SecFile
	
	attr_accessor :entries, :fn
	
	def initialize(fn = 'ytmsec.csv')
		@entries = []
		@fn = fn
	end
	
	# load 
	def load
		if File.exists?(@fn)
			puts "Loading"
		else
			return
		end
		CSV.foreach(@fn,"r") do |r|
			e = Security.new
			e.symbol = r[0]
			e.purchaseDate = r[1]
			e.matureDate = r[2]
			e.purchasePrice = r[3]
			e.maturityPrice = r[4]
			e.dividend = r[5]
			e.freq = r[6]
			e.nextDivDate = r[7]
			e.couponRate = r[8]
			e.currentYield = r[9]
			e.ytm = r[10]
			e.cagr = r[11]
			e.disc = r[12] if r[12]
			# don't import dups
			addIt = true
			$secFile.entries.each_index do |i|
				h = $secFile.entries[i]
				if h.symbol == e.symbol && h.purchaseDate == e.purchaseDate
					addIt = false
					puts "Have #{e.symbol}"
					break
				end
			end
			$secFile.entries << e if addIt
		end
		$tainted = false
	end
	
	def save
		return if @entries.length < 1
		fh = File.open(@fn,'w')
		@entries.each do |e|
			CSV::Writer.generate(fh) do |h|
				h << [e.symbol, e.purchaseDate, e.matureDate, e.purchasePrice,
					  e.maturityPrice, e.dividend, e.freq, e.nextDivDate,
					  e.couponRate, e.currentYield, e.ytm, e.cagr, e.disc]
			end
		end
		fh.close()
		$tainted = false
	end
	
end

class YTMGUI < Shoes
	url "/", :setupscreen
	url "/entry", :entryscreen
	url "/help", :helpscreen
	
	# helper funtions that need to be in the Shoes class
	# returns a string of a rate * 100 with a '%' on the end. 
	def displayRate(rtstr)
		rtf = rtstr.to_f
		return sprintf("%2.04f%%",rtf*100.0)
	end

	# check for reasonable dates - not perfect
	def verifyDtStr(dts)
		ok = false
		if dts.length == 10 and dts =~ /(\d\d)\/(\d\d)\/(\d\d\d\d)/
			m = $1.to_i
			d = $2.to_i
			y = $3.to_i
			ok = true if (m >= 1 and m <= 12) and (d >= 1 and d <= 31) and
				(y > 1900 and y < 2100)
		end
		#puts "#{m}/#{d}/#{y} is #{ok}"
		return ok
	end

	# this is called from setupscreen() so the object vars should be available
	# returns an array of the matching selected secFile.entries or nil
	def getSelected()
		ents = []
		lines = @seclist.contents()
		lines.each_index do |i|
			#line is a flow, columns will be whatever is formatted
			# Checkbox is first
			line = lines[i]
			columns = line.contents
			if columns[0].checked?
				ents << $secFile.entries[i]
			end
		end
		return ents
	end
	
	def setupscreen
    app.set_window_title("Yield To Maturity")
    app.set_window_icon_path(File.join(Dir.getwd,'ytm.png'))
    debug "In setupscreen #{$thisdir}"
    debug "Home: #{ENV['HOME']}"
		para "Select an entry to modify or create a new Security"
		@seclist = stack :height => 400
		$secFile.entries.each_index do |i|
			# format the entry for display
			longstr = $secFile.entries[i].format
			@seclist.append do
				flow do
					check
					#code longstr # no text shown, no errors in console
					para longstr, :font => "Monospace 14px" 
				end
			end
		end
		flow do
			button "New" do
				$secEnt = Security.new
				visit "/entry"
			end
			button "Edit" do
				# need to find the checkbox that is clicked.
				a = getSelected()
				if a and a.length > 0
					$secEnt = a[0]
					visit "/entry"
				end
			end
			button "Delete" do
				a = getSelected()
				if a.length > 0
					a.each {|ob| $secFile.entries.delete(ob)}
					$tainted = true
					visit "/"	# reload?
				end
			end
			button "Help" do
				visit "/help"
			end
		end
		para "For the whole collection you can"
		flow do
			button "Load" do
				if $tainted and confirm("Save current contents to #{$secFile.fn}?")
					$secFile.save
				end
				fn = ask_open_file
				if fn and fn.length > 0
					$secFile = SecFile.new(fn)
					$secFile.load
				end
			end
			button "Save" do
				$secFile.save
			end
			button "Save As..." do
				fn = ask_save_file
				if fn and fn.length > 0
					#puts "Setting new file #{fn}"
					$secFile.fn = fn
					$secFile.save
				end
			end
			button "Update Prices" do
				$tainted = true
			end
			button "Quit" do
				if $tainted and confirm("Save your modifications to #{$secFile.fn}")
					$secFile.save
				end
				exit()
			end
		end
	end
	
	
	# kooky to popup an alert here? 
	def datesOK()
		if verifyDtStr($secEnt.purchaseDate) == false or
			verifyDtStr($secEnt.matureDate) == false or
			verifyDtStr($secEnt.nextDivDate) == false
			alert "Check your dates\nThey need to be\nMM/DD/YYYY"
			return false
		end
		return true
	end
	
	#returns a hash of :symbol to string.
	def get_online(sym)
		ycodes = 'sl1d1dq'			# see TODO.txt for tips
		ret = {:code => '404'}
		resp = Net::HTTP.get_response('download.finance.yahoo.com',
				"/d/quotes.csv?s=#{sym}&f=#{ycodes}")
		ret[:code] = resp.code
		if resp.code == '200'
			flds = resp.body.split(',')		# really should use CSV:: for this
			ret[:symbol] = flds[0]
			ret[:price] = flds[1]
			ret[:date] = cleanDatestr(flds[2].delete('"'))
			ret[:dividend] = flds[3]		# it's annualized, be careful
			ret[:exdate] = flds[4].strip.delete('"')		# has no year, be careful and smart
		end
		return ret
	end
	
	def cleanDatestr(str)
		f= str.split('/')
		sprintf("%02d/%02d/%02d",f[0].to_i,f[1].to_i,f[2].to_i)
	end
	
	def entryscreen
		stack do
			para "This is the entry screen for setting up a security"
			flow do
				para "Yahoo Symbol"
				edit_line $secEnt.symbol do |k|
					$secEnt.symbol = k.text
				end
				button "Get Price" do
					resp = get_online($secEnt.symbol)
					if resp.nil? or resp[:code] != '200'
						alert "Bad symbol or comm failure #{resp[:code]}"
					else
						# use the results
						# watch out for "N/A" or 
						disp = "Use #{resp[:symbol]}, #{resp[:price]}"
						if confirm disp
							#$secEnt.purchaseDate = @purDtFld.text = resp[:date]
							$secEnt.purchasePrice = @purPrFld.text = resp[:price]
							#$secEnt.dividend = @divFld.text = resp[:dividend]
							#$secEnt.nextDivDate = @nextDtFld.text = resp[:exdate]
						end
					end
				end
			end
			flow do
				para "Purchase Date"
				@purDtFld = edit_line $secEnt.purchaseDate do |k|
					$secEnt.purchaseDate = k.text
				end
				para "Today if you don't own it"
			end
			flow do 
				para "Call date"
				edit_line $secEnt.matureDate do |k|
					$secEnt.matureDate = k.text
				end
				para "Or Maturity"
			end
			flow do 
				para "Face value"
				edit_line $secEnt.maturityPrice  do |k| 
					$secEnt.maturityPrice = k.text
				end
				para "in dollars"
			end
			flow do
				para "Current price"
				@purPrFld = edit_line $secEnt.purchasePrice do |k|
					$secEnt.purchasePrice = k.text
				end
				para " or your purchased price"
			end
			flow do
				para "Dividend amount"
				@divFld = edit_line $secEnt.dividend do |k|
					$secEnt.dividend = k.text
				end
				para "regular payment in dollars.cents"
			end
			flow do
				para "That regular payment is"
				stack :margin => 2 do 
				flow do
					@monFld = radio :guiFreg do |r|
						$secEnt.freq = '12' if r.checked?
					end
					para "Monthly"
				end
				flow do
					@qtFld = radio :guiFreg do |r|
						$secEnt.freq = '4' if r.checked?
					end
					para "Quarterly"
				end
				flow do
					@saFld = radio :guiFreg do |r|
						$secEnt.freq = '2' if r.checked?
					end
					para "Twice a year"
				end
				end
			end
			# looks are decieving. the following code sets the initial state
			# of the radios
			case $secEnt.freq
			when '12' then @monFld.checked = true
			when '4' then @qtFld.checked = true
			when '2' then @saFld.checked = true
			end
			flow do
				para "Next dividend Date"
				@nextDtFld = edit_line $secEnt.nextDivDate do |k|
					$secEnt.nextDivDate = k.text
				end	
				para " We have to know when the next payment is.",
				" I'll guess if you enter the last ex-div date."
			end
			flow do
				para "Reinvest income at rate 0.xy"
				edit_line $secEnt.disc do |k|
					$secEnt.disc = k.text
				end
			end
			para "Computed values"
			flow do
				para "Coupon Yield"
				@cupYldFld = edit_line displayRate($secEnt.couponRate),
					:state => 'readonly'
			end
			flow do
				para "Current Yield"
				@curYldFld = edit_line displayRate($secEnt.currentYield),
					:state => 'readonly'
			end
			flow :margin_right => 5 do
				para "Yield to Maturity", :width => 200
				@ytmFld = edit_line displayRate($secEnt.ytm),
					:state => 'readonly'
			end
			flow :margin_right => 5 do
				para "CAGR", :width => 200
				@cagrFld = edit_line displayRate($secEnt.cagr),
					:state => 'readonly'
			end
		end
		button "Calculate Yields" do
			if datesOK()
				$secEnt.compute
				@cupYldFld.text = displayRate($secEnt.couponRate)
				@curYldFld.text = displayRate($secEnt.currentYield)
				@ytmFld.text = displayRate($secEnt.ytm)
				@cagrFld.text = displayRate($secEnt.cagr)
			end
		end
		button "Cancel" do
			visit "/"
		end
		button "Keep" do
			# want to save
			if datesOK()
				$secEnt.compute
				# find it in secFile.entries and replace, append if not found
				append = true
				$secFile.entries.each_index do |i|
					if $secFile.entries[i].symbol == $secEnt.symbol
						append = false
						$secFile.entries[i] = $secEnt
						break
					end
				end
				$secFile.entries  << $secEnt if append
				$tainted = true
				visit "/"
			end
		end
	end
	
	def helpscreen
		stack do
			tagline "Calcaluations Could Be Wrong.",
			" Don't blame me if you discover that later."
			para "Coupon Yield - 1 years income divided by price at maturity"
			para "Current Yield - 1 years income dividend by current price"
			para "Yield to Maturity - A more accurate way for ",
			"comparing yields. It knows about both current and maturity prices",
			" and the dates involved and some consideration for the time value",
			" of your money"
			para "The one shown is the approximation YTM, about the same as",
			" what Excel might produce - I'm working on a more accurate one"
			para "CAGR - Combined Annual Growth Rate -",
			" assumes you don't reinvest your income stream.",
			" YTM does assumes you reinvest at the coupon rate which may not be",
			" reasonable . The truth will lie between CAGR and YTM numbers"
			para "The Reinvest rate is not a percentage! Default is 0.02",
			" which means 2%. It's the mulitplier for your dividend/coupons",
			" only CAGR cares about it so far. Yes, you can set it negative.",
			" No, I'm"," not certain it's worth my effort or yours"
			para "The ex-dividend date (your first payment) matters. I'll",
			" guess if you enter the last dividend date. My guess is more",
			" accurate than simple formulaic assumptions. When YTM and CAGR",
			" yary widely, its probably a dividend date If you are pricing a",
			" bond, this would be date you have own the bond to get the next",
			" coupon payment"
			para "Don't bother using this with preferreds or bonds with a",
			" maturity date less than one year from now"
			para "The main screen shows symbol, maturity date, YTM and CAGR"
			para "Pressing the Save button will save it to the file",
			" 'ytmsec.csv' . You may have to search for that file to find it.",
			" (ahem, Windows users)",
			" It's loaded when the program starts from where ever your OS puts it",
			"   Yes you can edit it, or load it into OpenOffice or that other",
			" spreadsheet."
			para "Feedback and questions to ccoupe@cableone.net"
		end
		button "Back" do
			visit "/"
		end
	end
end

$thisdir = Dir.getwd
$stderr.puts "Starting in #{$thisdir}"
debug "Looking In #{$thisdir}"
# Load the file and setup the globals
$secFile = SecFile.new
$secFile.load

# the next line fires up the GUI, calling the "/" url which maps to the setup
Shoes.app :width => 600, :height => 700, :margin => 5
