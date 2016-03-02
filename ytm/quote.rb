#!/usr/bin/env ruby
require 'net/http'
require 'csv'

ycodes = 'sl1d1dq'
#      LABELS = %w[ symbol name last date time net p_change volume bid ask
#		   close open day_range year_range eps pe div_date div
#		   div_yield cap ex_div avg_vol ].map { |label| label.to_sym }
#
#      FIELD_ENCODING = %w[ s n l1 d1 t1 c1 p2 v b a
#			   p o m w e r r1 d y j1 q a2 ]
# format is described at http://dirk.eddelbuettel.com/code/yahooquote.html
# dividend is for the year so divide it
# ex-date doesn't have a year. Have to guess. 
sym = 'GEJ'
resp = Net::HTTP.get_response('download.finance.yahoo.com',"/d/quotes.csv?s=#{sym}&f=#{ycodes}")
puts resp.code if resp.code != '200'
flds = resp.body.split(',')
flds.each_index {|k| puts "#{k}: #{flds[k]}"}
