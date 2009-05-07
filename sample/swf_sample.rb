require '../lib/swfmill_util'
require 'pp'

# initialize
swf = SwfmillUtil::Swf.new(File.open("sample.swf").read)

# check included images (object_id => Magick::Image)
pp swf.images #=> {"6"=> JPEG 176x208 176x208+0+0 DirectClass 8-bit 10kb, "3"=>  30x30 DirectClass 16-bit}
pp swf.texts #=> {"2"=>"\343\201\202\343\201\204\343\201\206\343\201\210\343\201\212ABC\r"}

# write included images
#swf.images.each do |i,image|
#  image.write("#{i}.#{image.format ? "jpg" : "gif"}")
#end

# replace included images
swf.images['3'] = Magick::Image.from_blob(File.open("flymelongirl.gif").read).first
swf.images['6'] = Magick::Image.from_blob(File.open("bg.jpg").read).first
swf.texts['2'] = "かきくけこXYZ"

# write swf replaced images
swf.write("foo.swf")
