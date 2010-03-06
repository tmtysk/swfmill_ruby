require '../lib/swfmill_ruby'
require 'pp'

################################################################################
# test to replace images and texts

# initialize
swf = SwfmillRuby::Swf.parseSwf(File.open("data/sample_original.swf").read)

# check included images (object_id => Magick::Image)
pp swf.images #=> {"6"=> JPEG 176x208 176x208+0+0 DirectClass 8-bit 10kb, "3"=>  30x30 DirectClass 16-bit}

# check included texts (object_id => String)
pp swf.texts #=> {"2"=>"\343\201\202\343\201\204\343\201\206\343\201\210\343\201\212ABC\r"}

# write included images
swf.images.each do |i,image|
  image.write("data/#{i}.#{image.format ? "jpg" : "gif"}")
  #=> write 3.gif and 6.jpg
end

# replace included images
swf.images['3'] = Magick::Image.from_blob(File.open("data/flymelongirl.gif").read).first
swf.images['6'] = Magick::Image.from_blob(File.open("data/bg.jpg").read).first
swf.texts['2'] = "かきくけこXYZ"

# write swf replaced images and texts
swf.write("data/replaced_image.swf")
