#
# draw ascii polygon given on command line
#
# Usage: ruby draw_ascii.rb polygon.txt
require 'stringio'

# add include path
$:.push('..')
require 'polygon'
require 'ascii_buffer'

fname = ARGV[0]
puts fname
p = Polygon.new
File.open(fname) {|f| p.load(f) }
puts p

ba = Ascci_Buffer.new(50, 20)
print ba.draw_polygon(p)
