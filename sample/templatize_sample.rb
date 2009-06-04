require '../lib/swfmill_util'
require 'pp'

################################################################################
# test to templatize movieclip

# initialize
swf = SwfmillUtil::Swf.parseSwf(File.open("data/sample_original.swf").read)
swf2 = SwfmillUtil::Swf.parseSwf(File.open("data/sample_original2.swf").read)

# check included movieclips (object_id => SwfmillUtil::Swf::DefineSprite)
pp swf.movieclips.keys #=> ["8", "5"]
pp swf2.movieclips.keys #=> ["6", "3"]

# check included movieclip_ids by instance_name
pp swf.movieclip_ids_named("animation") #=> ["5"]
pp swf2.movieclip_ids_named("animation") #=> ["6"]

# templatize movieclip specifying the mapping of object_ids
#  and available, unused object_id (if you want to adjust object_ids)
File.open("data/animation_template.xml", "w") do |f|
  f.puts swf2.movieclips["6"].templatize(true, 5, 1000)
end
